# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
# and distribute this software and its documentation, without fee and without a signed 
# licensing agreement, is hereby granted, provided that the above copyright notice, this 
# paragraph and the following two paragraphs appear in all copies, modifications, and 
# distributions.
#
# IN NO EVENT SHALL RODRIGO BOTAFOGO BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF 
# THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RODRIGO BOTAFOGO HAS BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# RODRIGO BOTAFOGO SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE 
# SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS". 
# RODRIGO BOTAFOGO HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
# OR MODIFICATIONS.
##########################################################################################

require 'fileutils'
require 'msgpack'

# Load required R libraries
dir = File.dirname(File.expand_path('.', __FILE__))
# Polyglot.eval_file('R', "#{dir}/r_libs.R")

# Bridge and Support first
require_relative 'rsupport'

# Operator modules next (so R::Object can include them)
require_relative 'rbinary_operators'
require_relative 'runary_operators'
require_relative 'rlogical_operators'
require_relative 'rindexed_object'
require_relative 'rmd_indexed_object'

# Now R::Object
require_relative 'robject'

module R
  # Raised when R.batch hits an R error mid-batch (later ops are not executed).
  class BatchEvaluationError < StandardError
    attr_reader :failed_index

    def initialize(message, failed_index = nil)
      super(message)
      @failed_index = failed_index
    end
  end

  # R↔Ruby bridge: NewBridge only.
  def self.bridge
    require_relative 'new_bridge_adapter'
    R::NewBridgeAdapter.instance
  end

  RCONSTANTS = ["LETTERS", "letters", "month.abb", "month.name", "pi"]

  #----------------------------------------------------------------------------------------
  # Executes a missing method. If a block is given, then the method needs to be executed
  # in the scope of the block.  @bug: Not ready yeat
  #----------------------------------------------------------------------------------------

  def self.method_missing(symbol, *args, &block)
    
    if (block_given?)
      val = R::Support.process_missing(symbol, false, *args)
      return R::Support.new_scope(symbol, val, *args, &block)
    end

    R::Support.process_missing(symbol, false, *args)

  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.internal_eval(symbol, *args)
    R::Support.process_missing(symbol, true, *args)
  end

  # Queue several eval_r_with_result assignments and send them in one bridge round-trip.
  # Fail-fast: on the first R error, remaining queued ops are not run (+R::BatchEvaluationError+,
  # +#failed_index+ is 0-based). Same outcomes as sequential +eval_r_with_result+ when all succeed.
  def self.batch
    col = R::Support::BatchCollector.new
    yield col
    raise ArgumentError, 'R.batch requires at least one eval_with_result assignment' if col.ops.empty?

    R::Support.batch_eval_with_result(col.ops)
  end

  # Async string eval against R; +block+ receives +NewBridge::EvalResult+ (+#value+ matches +eval_r+ on success).
  def self.eval_r_async(code, timeout: nil, &block)
    R.bridge.eval_r_async(code, timeout: timeout, &block)
  end

  # Async R function calls without blocking the caller. Requires a block; completion receives +NewBridge::EvalResult+.
  # (+R.foo { ... }+ is reserved for dplyr-style scopes; use +R::Async.foo(...)+ for async completion.)
  module Async
    def self.method_missing(symbol, *args, **kwargs, &block)
      raise ArgumentError, 'R::Async method calls require a block' unless block

      timeout = kwargs.delete(:timeout)
      name = R::Support.convert_symbol2r(symbol)
      R::Support.exec_function_async(name, *args, timeout: timeout, **kwargs, &block)
    end
  end

  #----------------------------------------------------------------------------------------
  # Checks to see if the given libs are installed in R and if not, install them
  # @param libs [Array] Array of strings with the names of the libraries to check and
  # install
  #----------------------------------------------------------------------------------------

  def self.with_callback_timeout_ms(callback_timeout_ms)
    return yield if callback_timeout_ms.nil?

    old = ENV['GALAAZ_CALLBACK_TIMEOUT_MS']
    ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = Integer(callback_timeout_ms).to_s
    yield
  ensure
    ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = old unless callback_timeout_ms.nil?
  end

  def self.install_rlibs(*libs, install_timeout_sec: nil, callback_timeout_ms: nil, bridge_timeout_sec: nil)
    with_callback_timeout_ms(callback_timeout_ms) do

      # Use a fixed local library directory and ensure R can see it
      lib_dir = File.expand_path("~/R/x86_64-pc-linux-gnu-library/galaaz")
      FileUtils.mkdir_p(lib_dir) unless Dir.exist?(lib_dir)
      R.bridge.eval_r(".libPaths(c('#{lib_dir.gsub("'", "\\\\'")}', .libPaths()))", timeout: bridge_timeout_sec)

      packages = R.c(*libs)

    # installed.packages() returns a matrix; package names are in the row names.
    # Using [:all, "Package"] on this matrix ends up calling [[ with a missing
    # row subscript in R, which raises "missing subscript". Instead, rely on
    # the row names vector for the list of installed packages.
    installed_mat   = R.installed__packages(nil)
    installed_names = R.rownames(installed_mat)

    new_packages = packages[!(packages._ :in, installed_names)]
    new_packages_str = new_packages.to_s

      if(new_packages.length > 0 && new_packages_str != "character(0)")
      $stderr.puts "[RUBY] The following packages are missing and will be installed: #{new_packages_str}"
      $stderr.puts "[RUBY] Installing to: #{lib_dir}"
      
      # Get packages as Ruby array using :native mode
      pkg_list = []
      new_packages.each(:native) { |pkg| pkg_list << pkg }
      $stderr.puts "[RUBY] Package list: #{pkg_list.inspect}"
      
      # Install each package
      pkg_list.each do |pkg|
        $stderr.puts "[RUBY] Installing #{pkg}..."
        if install_timeout_sec
          timeout_i = Integer(install_timeout_sec)
          R.bridge.eval_r("options(timeout=#{timeout_i})", timeout: bridge_timeout_sec)
        end
        r_cmd = "install.packages('#{pkg.gsub("'", "\\\\'")}', repos='https://cloud.r-project.org', lib='#{lib_dir.gsub("'", "\\\\'")}', dependencies=NA)"
        $stderr.puts "[RUBY] R command: #{r_cmd}"
        result = R.bridge.eval_r(r_cmd, timeout: bridge_timeout_sec)
        $stderr.puts "[RUBY] Install output: #{result.inspect}"
        if result.to_s.include?("ANTICONF") || result.to_s.include?("Configuration failed")
          $stderr.puts "[RUBY] WARNING: Package #{pkg} failed to install due to missing system libraries."
          $stderr.puts "[RUBY] For kableExtra, you may need: libfontconfig1-dev libxml2-dev libfreetype6-dev"
        end
      ensure
        begin
          R.bridge.eval_r("options(timeout=60)", timeout: bridge_timeout_sec)
        rescue StandardError
          nil
        end
      end
      
      # Re-check installed packages after install attempt
      installed_mat = R.installed__packages(nil)
      installed_names = R.rownames(installed_mat)
      still_missing = packages[!(packages._ :in, installed_names)]
      if still_missing.length > 0
        raise "Failed to install packages: #{still_missing.to_s}. Check stderr output above for [RUBY] debug messages."
      end
      end

    end
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.install_and_loads(*libs, install_timeout_sec: nil, callback_timeout_ms: nil, bridge_timeout_sec: nil)
    R.install_rlibs(*libs, install_timeout_sec: install_timeout_sec, callback_timeout_ms: callback_timeout_ms, bridge_timeout_sec: bridge_timeout_sec)
    # Use library() so load failures throw immediately with a clear R error
    libs.each { |lib| R.library(lib) }
  end

  #--------------------------------------------------------------------------
  # rlang helpers (reintroduced legacy API surface)
  #--------------------------------------------------------------------------

  def self.ensure_rlang!
    ok = R::Support.eval("requireNamespace('rlang', quietly=TRUE)")
    return if ok == true

    raise "R package 'rlang' is required for this API. Install with: Rscript -e \"install.packages('rlang', repos='https://cloud.r-project.org/')\""
  end

  # Build an R expression/symbol using rlang::expr().
  def self.expr(arg)
    ensure_rlang!
    var_name = R::Support.generate_var_name
    parsed = R::Support.parse_arg(arg)
    R.bridge.eval_r("#{var_name} <- rlang::expr(#{parsed})")
    R::Object.build(var_name)
  end

  # Build a call object with rlang::call2().
  def self.call2(fn, *args, **kwargs)
    ensure_rlang!
    var_name = R::Support.generate_var_name
    parts = [R::Support.parse_arg(fn)]
    parts.concat(args.map { |a| R::Support.parse_arg(a) }) unless args.empty?
    unless kwargs.empty?
      kw = kwargs.map { |k, v| "#{k.to_s.gsub(/__/, ".")} = #{R::Support.parse_arg(v)}" }
      parts.concat(kw)
    end
    R.bridge.eval_r("#{var_name} <- rlang::call2(#{parts.join(', ')})")
    R::Object.build(var_name)
  end

  # Execute a function call with dynamic args via rlang::exec().
  def self.exec(fn, *args, **kwargs)
    ensure_rlang!
    R.rlang___exec(fn, *args, **kwargs)
  end
  
end

# Ruby class extensions.  Extends Symbol to allow the creation of
# expressions using Symbol: (:x > 10)
require_relative 'ruby_extensions'

# define methods for accessing indexed object: Vector, Lists
require_relative 'rindexed_object'
# define methods for accessing multi dimensional indexed objects: Matrix, DataFrames
require_relative 'rmd_indexed_object'

# Definition of R Vector.  Vectors include Unary and Binary operators
require_relative 'rvector'
# Definition of R Lists
require_relative 'rlist'
# Definition of R Matrix
require_relative 'rmatrix'
# Definition of R DataFrame
require_relative 'rdata_frame'
# Definition of R Closure (functions)
require_relative 'rclosure'
# Definition of R Expression
require_relative 'rexpression'
# Definition of R Environment
require_relative 'renvironment'
# Definition of R Language
require_relative 'rlanguage'
# Definition of R Symbol
require_relative 'rsymbol'
# Device for ggplot (png/svg, plot_snapshot, save_plot)
require_relative 'rdevice'
# Access to package symbols
require_relative 'rpkg'

# Arrow helpers (tables, datasets, Feather/Parquet IO)
require_relative 'r_arrow'

# Class to allow R calling back into Ruby
require_relative 'ruby_callback'
