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
  
  module RubyExpression
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def self.parse_expression(exp)
      
      case exp
      when Symbol, Numeric
        exp.to_s
      when R::Language
        R.get_expr(exp)
      when String
        "\"#{exp}\""
      when R::NotAvailable
        "NA"
      when Range   
        final_value = (exp.exclude_end?)? (exp.first > exp.last)?
                        (exp.last + 1) : (exp.last - 1)
                      : exp.last
        "(#{exp.first}:#{final_value})"
      when NegRange
        "-(#{exp.first}:#{exp.last})"
      when Hash
        params = []
        envs = R.list
        exp.each_pair do |key, value|
          k = key.to_s.gsub(/__/,".")
          # value = "\"#{value}\"" if value.is_a? String
          value = parse_expression(value)
          params << "#{key} = #{value}"
        end
        params.join(", ")
      when :all
        "."
      when Proc, Method
        e = R.enq(exp, proc: R::RubyCallback.build(exp))
        "proc"
      else
        # raise "Expression #{exp} is of type #{exp.class} and cannot be part of an expression"
        puts "in else"
        puts exp.class
        exp
      end
      
    end
    
    #--------------------------------------------------------------------------------------
    # Build a new expression from the given argument.
    # @param args [Array] size of array should be either 1 or 3.  When 3, then it is of
    #   the form '<operand> <binary operator> <operand>'
    #--------------------------------------------------------------------------------------
    
    def self.build(*args)
      
      case args.size
      when 1
        op1 = parse_expression(args[0])
        rhs = R.rhs(R.as__formula("~ #{op1}"))
        R.enq(rhs)
      when 3
        op1 = parse_expression(args[0])
        op2 = parse_expression(args[2])
        optr = args[1].delete("`")
        # @TODO: when there is a '^' in the expression, it should be treated as a
        # formula. 
        formula = (optr == "~")? true : false
        rhs = R.rhs(R.as__formula("~ #{op1} #{optr} #{op2}"))
        R.enq(rhs)
      else
        raise "Expressions can be build with either 1 or 3 arguments, got #{args.zie}"
      end
      
    end

  end
  
  #--------------------------------------------------------------------------------------
  # Module for binary operators when creating working with expressions, things like:
  # :a + :b, where when send to the R engine should be converted to some language
  # construct, formula, quosure or similar.
  #--------------------------------------------------------------------------------------
  
  module ExpBinOp
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def exec_bin_oper(operator, other_object)
      # R::Expression.build(self, operator, other_object)
      R::RubyExpression.build(self, operator, other_object)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def coerce(numeric)
      [R::RubyExpression.build(numeric), self]
    end

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
    var = (self == :all)? '.' : to_s
    R::Object.build(R::Support.eval("as.name").call(var))
  end

  #--------------------------------------------------------------------------------------
  # Unary '~' retrieves the values of the R symbol
  #--------------------------------------------------------------------------------------

  def ~@
    R::Object.build(R::Support.eval(to_s))
  end
    
end
