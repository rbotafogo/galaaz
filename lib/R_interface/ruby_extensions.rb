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

#==========================================================================================
#
#==========================================================================================

module R

  module ExpBinOp

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def exec_bin_oper(operator, other_object)
      R::Support.exec_function(R::Support.create_bin_expr(operator), self,
                               other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def coerce(numeric)
      [R::RubyExpression.build_bin_exp(numeric), self]
    end

  end
  
end

#==========================================================================================
#
#==========================================================================================

module E

  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    rargs = R.exprs(name.to_sym, *args)    
    R.as__call(rargs)
  end
  
end

#==========================================================================================
#
#==========================================================================================

class Range

  #----------------------------------------------------------------------------------------
  # Defines unary minus operation for ranges
  #----------------------------------------------------------------------------------------
  
  def -@
    final_value = (exclude_end?)?
                    (first > last)?
                      (last + 1) : (last - 1)
                  : last
    NegRange.new(self.begin, final_value)
  end

end

#==========================================================================================
# Class NegRange exists to represent a negative range, e.g., -(1...10).  Such a range is
# used to index vectors and means all elements but the ones in the given range.  Class
# NegRange is parsed to become "-(1:10)" in R.
#==========================================================================================

class NegRange < Range

end

#==========================================================================================
#
#==========================================================================================

class Symbol
  include R::BinaryOperators
  include R::ExpBinOp
  include R::LogicalOperators
  
  #--------------------------------------------------------------------------------------
  # Unary '+' converts a Ruby Symbol into an R Symbol
  #--------------------------------------------------------------------------------------

  def +@
    R.expr(self)
  end

  #--------------------------------------------------------------------------------------
  # Unary '~' retrieves the values of the R symbol
  #--------------------------------------------------------------------------------------

  def ~@
    R::Object.build(R::Support.eval(to_s))
  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def succ
    self.to_s.succ.to_sym
  end
  
  #----------------------------------------------------------------------------------------
  # We use the following notation to access binary R functions such as %in%:
  # R.vec_ "in", list.
  # @param args [Array] The first element of the array is an R infix function, the other
  # arguments are the list of arguments for the function.
  #----------------------------------------------------------------------------------------
  
  def _(*args)
    name = "%#{args.shift.to_s}%"
    args.unshift(self)
    rargs = R.exprs(name, *args)
    R.as__call(rargs)
  end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def assign(expression)
    exec_bin_oper("`<-`", expression)
  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def assign2(expression)
    exec_bin_oper("`=`", expression)
  end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def method_missing(symbol, *args, &block)

    E.send(symbol.to_s, self, *args)
    
  end

  #--------------------------------------------------------------------------------------
  # Used when selecting column in a data frame, from the first column to the var2
  # column
  #--------------------------------------------------------------------------------------
  
  def up_to(var2)
    R::Support.exec_function(R::Support.range, self, var2)
  end

  
  #--------------------------------------------------------------------------------------
  # Create an interaction between two variables in formulas
  #--------------------------------------------------------------------------------------
  
  def inter(var2)
    R::Support.exec_function(R::Support.range, self, var2)
  end
  
  #--------------------------------------------------------------------------------------
  # If method_missing is implemented, then we also need to implement method 'to_ary'.
  # This is because starting from ruby 1.9 the code for Array#flatten has changed,
  # calling 'to_ary' blindly (even if the method is not implemented).  This causes
  # the method to be caught by 'method_missing' and here sending a 'to_ary' no found
  # error.  If we create to_ary, then no error is issued.
  # @TODO: make sure that implementing 'to_ary' as bellow will not create problems
  #--------------------------------------------------------------------------------------

  def to_ary
    # [self.to_s]
  end

end
