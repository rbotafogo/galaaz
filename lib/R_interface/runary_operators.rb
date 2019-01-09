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

  module ExecUniOp

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def exec_uni_oper(operator)      
      R::Support.exec_function_name(operator, @r_interop)
    end
    
  end


  module ExpUniOp

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def exec_uni_oper(operator)
      # op1 = prep(self)
      # op2 = prep(other_object)      
      # R::Expression.build(operator, self)
      optr = operator.delete("`")
      R::Expression.build("#{operator}#{self}")
    end

  end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  module UnaryOperators

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def !
      # R::Support.exec_function_name("`!`", @r_interop)
      exec_uni_oper("`!`")
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def -@
      # R::Support.exec_function_name("`-`", @r_interop)
      exec_uni_oper("`-`")
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def +@
      # R::Support.exec_function_name("`+`", @r_interop)
      exec_uni_oper("`+`")
    end

  end

end
