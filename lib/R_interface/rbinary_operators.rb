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

    def exec_oper(operator, other_object)
      R::Support.exec_function_name(operator, @r_interop, other_object)
    end

  end

  #--------------------------------------------------------------------------------------
  # Module for binary operators when creating an expression (call)
  #--------------------------------------------------------------------------------------

  module CallBinOp

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def exec_oper(operator, other_object)
      R::Language.build(operator, self, other_object)
    end

  end

  #--------------------------------------------------------------------------------------
  # Module for binary operators when creating formulas
  #--------------------------------------------------------------------------------------

  module FormulaBinOp
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def prep_object(object)
      
      case object
      when :all
        '.'
      when R::RSymbol, Symbol
        object.to_s
      when R::Language
        R.deparse(object).substring(2)
      when String
        object
      end
      
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def exec_oper(operator, other_object, response = false)

      o1 = prep_object(self)
      o2 = prep_object(other_object)

      response ? R.reformulate(o2, response: o1) :
         R.reformulate(R.paste0(o1, operator.delete("`"), o2))
      
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

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

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def ==(other_object)
      exec_oper("`==`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def <(other_object)
      exec_oper("`<`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def <=(other_object)
      exec_oper("`<=`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def >(other_object)
      exec_oper("`>`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def >=(other_object)
      exec_oper("`>=`", other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def !=(other_object)
      exec_oper("`!=`", other_object)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def &(other_object)
      R::Support.exec_function_name("`&`", @r_interop, other_object.r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def |(other_object)
      R::Support.exec_function_name("`|`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def coerce(numeric)
      [R.c(numeric), self]
    end

  end

end
