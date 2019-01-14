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
=begin
  R::Support.eval(<<-R)
    bang_bang = function() {
      print("in bang_bang")
      x = enquo(obj)
      # enexpr(class(!!x))
      print(x)
      x
    }

    with_env <- function(f, e=parent.frame()) {
      stopifnot(is.function(f))
      environment(f) <- e
      f()
    }

    expr = function(x) {
      enexpr(x)
    }

    ast = function(x) {
      ex = enexpr(x)
      lobstr::ast(!!ex)
    }

  R

  module RubyExpression
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def self.parse_expression(exp)
      
      case exp
      when Symbol, Numeric, R::Language
        exp.to_s
      # when R::Language
      # R.get_expr(exp)
      # exp.to_s
      when String
        "\"#{exp}\""
      when R::NotAvailable
        "NA"
      when TrueClass
        "TRUE"
      when FalseClass
        "FALSE"
      when Range   
        final_value = (exp.exclude_end?)? (exp.first > exp.last)?
                        (exp.last + 1) : (exp.last - 1)
                      : exp.last
        "(#{exp.first}:#{final_value})"
      when NegRange
        "-(#{exp.first}:#{exp.last})"
      when :all
        "."
      when Proc, Method
        # R::Support.enquo(exp, proc: R::RubyCallback.build(exp))
        # e = R.enq(exp, proc: R::RubyCallback.build(exp))
        R.new_object = R::RubyCallback.build(exp)
        "!!new_object"
      when Hash
        params = []
        # envs = R.list
        exp.each_pair do |key, value|
          k = key.to_s.gsub(/__/,".")
          # value = "\"#{value}\"" if value.is_a? String
          value = parse_expression(value)
          params << "#{key} = #{value}"
        end
        params.join(", ")
      when R::Object
        # @TODO: I don't like setting a value on R's global environment, but this was the
        # only way to get the '!!new_object' to become an expression. Should be careful
        # with this and could have problems if this runs in multiple threads.
        R.new_object = exp
        "!!new_object"
      else
        raise "Expression #{exp} is of type #{exp.class} and cannot be part of an expression"
        # puts "in else"
        # puts exp.class
        # exp
      end
      
    end

    #--------------------------------------------------------------------------------------
    # Build a new expression from the given argument.
    #--------------------------------------------------------------------------------------

    def self.build_uni_exp(exp)
      op1 = parse_expression(exp)
      # R.expr(exp)
      rhs = R.rhs(R.as__formula("~ #{op1}"))
      R.substitute(rhs)
    end
    
    #--------------------------------------------------------------------------------------
    # Build a new expression from the given argument.
    #--------------------------------------------------------------------------------------
    
    def self.build_bin_exp(oper1, func, oper2)
      op1 = parse_expression(oper1)
      op2 = parse_expression(oper2)
      optr = func.delete("`")
      # @TODO: when there is a '^' in the expression, it should be treated as a
      # formula. 
      formula = (optr == "~")? true : false
      
      rhs = R.rhs(R.as__formula("~ #{op1} #{optr} #{op2}"))
      R.substitute(rhs)
      # R.enq(rhs)
    end
    
  end
  
  #--------------------------------------------------------------------------------------
  # Module for binary operators when creating working with expressions, things like:
  # :a + :b, where when send to the R engine should be converted to some language
  # construct, formula, quosure or similar.
  #--------------------------------------------------------------------------------------
=end  
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
=begin    
    def exec_bin_oper(operator, other_object)
      # R::Expression.build(self, operator, other_object)
      # R::RubyExpression.build(self, operator, other_object)
      R::RubyExpression.build_bin_exp(self, operator, other_object)
    end
=end
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def coerce(numeric)
      [R::RubyExpression.build_bin_exp(numeric), self]
    end

  end
  
end

#=========================================================================================
#
#=========================================================================================
=begin
module E

  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)

    params = []
    args.each do |arg|
      # puts arg
      params << R::RubyExpression.parse_expression(arg)
      # params << R::RubyExpression.build(arg)
    end

    exp = "#{name}(#{params.join(", ")})"
    # R.substitute(R.rhs(R.as__formula("~ #{name}(#{params.join(", ")})")))
    R.expr(R.substitute(R.rhs(R.as__formula("~ #{name}(#{params.join(", ")})"))))
  end
  
end
=end

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
  # include R::CallBinOp

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
    
end
