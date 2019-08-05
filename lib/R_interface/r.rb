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

# Load required R libraries
dir = File.dirname(File.expand_path('.', __FILE__))
Polyglot.eval_file('R', "#{dir}/r_libs.R")

require_relative 'robject'
require_relative 'rsupport'

module R

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

  #----------------------------------------------------------------------------------------
  # Checks to see if the given libs are installed in R and if not, install them
  # @param libs [Array] Array of strings with the names of the libraries to check and
  # install
  #----------------------------------------------------------------------------------------

  def self.install_rlibs(*libs)

    packages = R.c(*libs)

    new_packages = packages[!(packages._ :in, R.installed__packages[:all, "Package"])]
    puts new_packages
    
    if(new_packages.size > 0)
      
      # package 'data_table' cannot be installed by install.packages.  FastR implements
      # install.fastr.packages for installing 'data_table'
      if ((R.c('data.table')._ :in, new_packages) >> 0)
        new_packages = new_packages[!'data_table']
        R.install__fastr__packages('data_table')
      end
      
      puts "The following packages are missing and will be installed:\n #{new_packages}"
      R.install__packages(new_packages)
    end
    
  end

  #----------------------------------------------------------------------------------------
  #
  #----------------------------------------------------------------------------------------

  def self.install_and_loads(*libs)
    R.install_rlibs(*libs)
    libs.each { |lib| R.require lib }
  end
  
end

# Binary operators: '+', '-', etc
require_relative 'rbinary_operators'
# Unary operators: '!', '@-', etc
require_relative 'runary_operators'
# Logical operators
require_relative 'rlogical_operators'

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
# Access to package symbols
require_relative 'rpkg'

# Class to allow R calling back into Ruby
require_relative 'ruby_callback'
