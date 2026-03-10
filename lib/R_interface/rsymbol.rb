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
  #
  #--------------------------------------------------------------------------------------

  class RSymbol < R::Object
    include BinaryOperators
    include ExecBinOp
    include LogicalOperators

    def class
      ::R::RSymbol
    end

    def rclass
      res = ::R::Support.exec_function("class", ::R::Support.exec_function("eval", self))
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    def typeof
      res = ::R::Support.exec_function("typeof", ::R::Support.exec_function("eval", self))
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    # Symbol name as string (e.g. "read.table") for call[[1]].to_s.
    def to_s
      return super unless ::R.bridge.ready?
      raw = ::R.bridge.eval_r("as.character(#{@r_interop})").to_s
      m = raw.match(/\[1\]\s*"([^"]*)"/)
      m ? m[1] : raw.strip
    end

    def exec_bin_oper(operator, other_object)
      # Use infix notation: lhs operator rhs, but evaluate self
      op = operator.delete("`")
      
      var_name = ::R::Support.generate_var_name
      lhs = "eval(#{@r_interop})"
      
      # If other object is a symbol, evaluate it too
      rhs = if other_object.is_a?(::R::RSymbol)
              "eval(#{other_object.r_interop})"
            else
              ::R::Support.parse_arg(other_object)
            end
      
      ::R.bridge.eval_r("#{var_name} <- #{lhs} #{op} #{rhs}")
      ::R::Object.build(var_name)
    end
    
    def exec_uni_oper(operator)
      op = operator.delete("`").strip
      var_name = ::R::Support.generate_var_name
      ::R.bridge.eval_r("#{var_name} <- #{op}(eval(#{@r_interop}))")
      ::R::Object.build(var_name)
    end
    
=begin    
    #--------------------------------------------------------------------------------------
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def =~(other_object)
      # puts "doing #{self} =~ #{other_object}"
      exec_bin_oper("`~`", other_object, true)
    end
=end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def ^(other_object)
      exec_bin_oper("`:`", other_object)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

  end
  
end
