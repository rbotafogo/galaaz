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
  
  class Language < Object
    include BinaryOperators
    include ExpBinOp
    # include FormulaBinOp

    attr_accessor :expression
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def self.to_expression(obj)
      obj.respond_to?(:expression) ? obj.expression : obj.to_s
    end
    
    #--------------------------------------------------------------------------------------
    # Builds a call functions with the given arguments. 
    # @param function_name [String] name of the function to apply: ex: '+'
    # @param args [Array] two elements array for the binary function: ex [:a, :b]
    # @return call expression.  With the above paramenters the result would be:
    #    .Primitive("+")(a, b)
    #--------------------------------------------------------------------------------------

    def self.build(function_name, *args)
      
      res = R::Language.new(
        R::Support.eval("as.call").
          call(R::Support.parse2list(
                 R::Support.eval(function_name), *args)
              ))
      res.expression = "#{Language.to_expression(args[0])} #{function_name.delete("`")} #{Language.to_expression(args[1])}"
      res
      
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def i
      "I(#{@expression})"
    end
    
  end
  
end
