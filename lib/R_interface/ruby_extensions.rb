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
      f = R::Support.eval(<<-R)
        function(op1, op2) {
          o1 = enexpr(op1)
          o2 = enexpr(op2)
          expr(#{operator}(!!o1, !!o2))
        }
        R
      R::Support.exec_function(f, self, other_object)
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

  #--------------------------------------------------------------------------------------
  # Unary '+' converts a Ruby Symbol into an R Symbol
  #--------------------------------------------------------------------------------------

  def +@
    # var = (self == :all)? '.' : to_s
    # R::Object.build(R::Support.eval("as.name").call(var))
    # R::RubyExpression.build_uni_exp(self)
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

  def assign(expression)
    exec_bin_oper("`<-`", expression)
  end
  
end

