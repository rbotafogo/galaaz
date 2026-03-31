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

require 'stringio'
require 'tmpdir'

#----------------------------------------------------------------------------------------
# Class RC is used only as a context for all ruby chunks in the rmarkdown file.
# This allows for chunks to access local variables defined in other chunks.
#----------------------------------------------------------------------------------------

class RC

  attr_reader :out_list

  def initialize
    @out_list = R.list
  end

  def outputs(obj)
    @out_list = R.c(@out_list, obj)
  end

  # In gknit, stdout is redirected to StringIO. Under JRuby, Kernel.puts can treat
  # R::Vector as array-like (to_ary) and print one element per line. Normalize R
  # objects to their R printed form first, so `puts vec` matches gstudio (`[1] ...`).
  def normalize_output_arg(arg)
    return arg.to_s if arg.is_a?(::R::Object)
    return arg.map { |item| normalize_output_arg(item) } if arg.is_a?(::Array)
    arg
  end

  def puts(*args)
    return ::Kernel.puts if args.empty?
    ::Kernel.puts(*args.map { |arg| normalize_output_arg(arg) })
  end

  def print(*args)
    ::Kernel.print(*args.map { |arg| normalize_output_arg(arg) })
  end

  def reset_outputs
    @out_list = nil
  end

  def get_binding
    binding
  end
  
end

RChunk = RC.new
RCbinding = RChunk.get_binding

#----------------------------------------------------------------------------------------
#
#----------------------------------------------------------------------------------------

module GalaazUtil

  # Read a logical-ish knitr option directly from the options list on the R side.
  # This avoids wrapper-shape differences when values arrive as handles/lists via NewBridge.
  def self.knitr_option_trueish?(options, key, default: true)
    return default unless options && options.respond_to?(:r_interop)

    key_esc = key.to_s.gsub("'", "\\\\'")
    txt = R.bridge.eval_r("as.character(#{options.r_interop}[['#{key_esc}']])").to_s
    token = txt.sub(/\A\[\d+\]\s*/, '').gsub('"', '').strip.upcase
    return true if token == 'TRUE'
    return false if token == 'FALSE'
    return default if token == '' || token == 'NA' || token == 'NULL'
    return token.to_f != 0.0 if token.match?(/\A-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\z/)

    default
  rescue StandardError
    default
  end

  # Knitr chunk options are often R logical NA ("inherit global default"). Those must not be
  # treated as false (see R::Vector#unboxed_get: NA → nil). Defaults match knitr: eval/echo/include/message/warning TRUE.
  def self.knitr_logical_trueish?(opt)
    return true if opt.nil?
    return opt if opt == true || opt == false

    raw = opt.unboxed_get(0) if opt.respond_to?(:unboxed_get)
    return true if raw.nil?
    return raw if raw == true || raw == false
    return raw != 0 if raw.is_a?(Numeric)
    return !raw.to_s.strip.casecmp('FALSE').zero? if raw.respond_to?(:to_s)

    true
  end

  #----------------------------------------------------------------------------------------
  # Executes the ruby code with the given options.
  # @param options [R::List] An R list of options
  # @return [R::List] an R list with everything that needs to be outputed.
  # The options are:
  # * options.code: the ruby code
  # * options[["eval"]]: evaluate if true
  # * options.echo: if true, show the source code of the chunk in the output
  # * options.message: if true, show error message if any exception in the ruby code
  # * options.warning: if true, show stack trace from the ruby code
  # * options.include: if true, include the code output
  # Note that we need to access the 'eval' element of the list by indexing as
  # options[["eval"]], this is because eval is a Ruby function and doing options.eval
  # will call the eval method on options, which is not what we want
  #----------------------------------------------------------------------------------------

  def self.exec_ruby(options)

    # RubyChunk.init

    # Read chunk code via a temp file (avoids result-protocol limits on long strings). Use Dir.tmpdir
    # so gknit works without /dev/shm (macOS, sandboxes, minimal containers).
    chunk_code_file = File.join(Dir.tmpdir, "galaaz_chunk_code_#{Process.pid}_#{Thread.current.object_id}.txt")
    path_lit = ::R::Support.parse_arg(chunk_code_file)
    begin
      R.bridge.eval_r("writeLines(paste(#{options.r_interop}[['code']], collapse='\\n'), #{path_lit})")
      code = File.read(chunk_code_file)
    ensure
      File.unlink(chunk_code_file) if chunk_code_file && File.file?(chunk_code_file)
    end
    # If the string arrived with literal \n (e.g. from R→Ruby transport), convert to real newlines so eval does not hit "unexpected backslash"
    code = code.gsub("\\n", "\n") if code.is_a?(String)
    # the output should be a list with the proper structure to pass to
    # function engine_output.  We first add the source code from the block to
    # the list. Pass src as a character vector of lines (not one string with \n)
    # so knitr preserves line breaks and indentation in the rendered chunk.
    if knitr_option_trueish?(options, 'echo', default: true)
      src_lines = code.lines.map(&:chomp)
      src_lines = [" "] if src_lines.empty?
      out_list = R.list(R.structure(R.list(src: R.c(*src_lines)), class: 'source'))
    else
      out_list = R.list
    end

    begin

      # set $stdout to a new StringIO object so that everything that is
      # output from instance_eval is captured and can be sent to the
      # report
      $stdout = StringIO.new

      # Execute the Ruby code in the scope of class RubyChunk. This is done
      # so that instance variables created in one chunk can be used again on
      # another chunk
      # RChunk.instance_eval(code) if (options[["eval"]].unboxed_get(0))
      eval(code, RCbinding, __FILE__, __LINE__ + 1) if knitr_option_trueish?(options, 'eval', default: true)
      
      # add the returned value to the list
      # this should have captured everything in the evaluation code
      # it is not working since at least RC10.
      out = $stdout.string
      
      out_list = R.c(out_list, out)
      
    rescue StandardError => e
      begin
        label = options['label'].unboxed_get(0).to_s
        GknitDiagnostics.record(chunk_label: label, error: e) if defined?(GknitDiagnostics)
      rescue StandardError
        nil
      end

      # Use R's simpleMessage/simpleWarning so knitr's engine_output can call conditionMessage() on them
      # g_simpleMessage transforms "; " to newlines then calls simpleMessage (defined in R engine setup)
      if knitr_option_trueish?(options, 'message', default: true)
        msg_cond = R.g_simpleMessage(e.message.to_s)
        out_list = R.c(out_list, msg_cond)
      end

      if knitr_option_trueish?(options, 'warning', default: true)
        bt = ""
        e.backtrace.each { |line| bt << line + "\n"}
        warn_cond = R.g_simpleWarning(bt)
        out_list = R.c(out_list, warn_cond)
      end

    rescue SyntaxError => e
      STDERR.puts "A syntax error occured in ruby block '#{options['label'].unboxed_get(0)}'"
      raise SyntaxError.new(e)
      
    ensure
      # return $stdout to standard output
      $stdout = STDOUT
    end
    
    # include=FALSE must still execute code (knitr semantics). Output suppression is handled
    # at engine emission stage, not here.
    out_list
    
  end
  
end
