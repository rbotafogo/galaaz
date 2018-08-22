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

require_relative 'robject'
require_relative 'rsupport'

module R

  RCONSTANTS = ["LETTERS", "letters", "month.abb", "month.name", "pi"]

  #----------------------------------------------------------------------------------------
  #
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
  #
  #----------------------------------------------------------------------------------------
  
  def self.as__data__frame(r_object)
    R::Support.exec_function(R::Support.as_data_frame, r_object)
  end

  #----------------------------------------------------------------------------------------
  # @bug Method all__equal is necessary because Interop dispatch is not working properly
  #----------------------------------------------------------------------------------------

  def self.all__equal(*args)
    R::Support.exec_function(R::Support.all_equal, *args)
  end

  #----------------------------------------------------------------------------------------
  # @bug Bug in Interop/FastR that does not call the function subset correctlry
  #----------------------------------------------------------------------------------------

  def self.subset(*args)
    R::Support.exec_function(R::Support.subset, *args)
  end

  #----------------------------------------------------------------------------------------
  # @bug Bug in Interop/FastR that does not call the function awt correctlry
  #----------------------------------------------------------------------------------------

  def self.awt
    R::Support.exec_function(R::Support.awt)
  end
  
  #----------------------------------------------------------------------------------------
  # converts R parameters to ruby wrapped R objects
  #----------------------------------------------------------------------------------------
=begin
  def self.r2ruby(*args)
    p *args
    *args
  end
=end

end

# define methods for accessing indexed object: Vector, Lists
require_relative 'rindexed_object'
# define methods for accessing multi dimensional indexed objects: Matrix, DataFrames
require_relative 'rmd_indexed_object'
# Binary operators: '+', '-', etc
require_relative 'rbinary_operators'
# Unary operators: '!', '@-', etc
require_relative 'runary_operators'
# Definition of R Vector
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

# Defines binary operators for expressions
require_relative 'expressions_bin_ops'
# Defines the E module for creating R expressions
require_relative 'expression'
# Ruby class extensions.  Extends Symbol to allow the creation of
# expressions using Symbol: (:x > 10)
require_relative 'ruby_extensions'
