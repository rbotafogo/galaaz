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

module R

  #--------------------------------------------------------------------------------------
  # Module for binary operators with normal elements: matrix, vector, etc.
  #--------------------------------------------------------------------------------------

  module ExecBinOp
        
    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def exec_oper(operator, operand2)      
      R::Support.exec_function_name(operator, @r_interop, operand2)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def ==(other_object)
      exec_oper("`==`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def coerce(numeric)
      [R.c(numeric), self]
    end

  end

  #--------------------------------------------------------------------------------------
  # Module for binary operators when creating working with expressions, things like:
  # :a + :b, where when send to the R engine should be converted to some language
  # construct, formula, quosure or similar.
  #--------------------------------------------------------------------------------------

  module ExpBinOp

    #--------------------------------------------------------------------------------------
    # In an expression, ':all' is converted to '.'.  '.' is not valid Ruby syntax in an
    # expression
    #--------------------------------------------------------------------------------------

    def prep(operand)
      (operand.eql? :all)? Expression.new('.') : operand
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def exec_oper(operator, other_object)
      op1 = prep(self)
      op2 = prep(other_object)      
      R::Expression.build(op1, operator, op2)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def eql(other_object)
      exec_oper("`==`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def coerce(numeric)
      [R::Expression.build(numeric), self]
    end

  end

  #--------------------------------------------------------------------------------------
  # Note that binary operators work on vectors and matrices as well as scalars. 
  #--------------------------------------------------------------------------------------
  
  module BinaryOperators

    #--------------------------------------------------------------------------------------
    # @param other_object
    #--------------------------------------------------------------------------------------

    def +(other_object)
      exec_oper("`+`", other_object)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def -(other_object)
      exec_oper("`-`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def *(other_object)
      exec_oper("`*`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def /(other_object)
      exec_oper("`/`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def **(other_object)
      exec_oper("`^`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def %(other_object)
      exec_oper("`%%`", other_object)
    end

    alias_method :mod, :%
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def <(other_object)
      exec_oper("`<`", other_object)
    end
 
    alias_method :lt, :<
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def <=(other_object)
      exec_oper("`<=`", other_object)
    end

    alias_method :le, :<=

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def >(other_object)
      exec_oper("`>`", other_object)
    end

    alias_method :gt, :>
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def >=(other_object)
      exec_oper("`>=`", other_object)
    end

    alias_method :ge, :>=
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def !=(other_object)
      exec_oper("`!=`", other_object)
    end

    alias_method :ne, :!=
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def &(other_object)
      exec_oper("`&`", other_object)
    end

    alias_method :and, :&
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def |(other_object)
      exec_oper("`|`", other_object)
    end

    alias_method :or, :|
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def ^(other_object)
      exec_oper("`~`", other_object)
    end
        
  end

end
