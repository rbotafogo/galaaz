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

  R::Support.eval(<<-R)
    enq = function(x, ...) {
      enquo(x)
    }
  R
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  class Expression
    include BinaryOperators
    include ExpBinOp
    include UnaryOperators
    include ExpUniOp
    
    attr_reader :infix
    attr_reader :prefix
    attr_reader :formula
    attr_accessor :environment
        
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def to_s
      @infix
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def formula?
      @formula
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def self.parse_expression(exp)

      case exp
      when Symbol, Numeric
        exp.to_s
      when R::Language
        R.get_expr(exp)
      when Expression
        exp.infix
      when String
        "\"#{exp}\""
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
      when R::NotAvailable
        "na"
      when NegRange
        "-(#{exp.first}:#{exp.last})"
      when Range   
        final_value = (exp.exclude_end?)? (exp.first > exp.last)?
                        (exp.last + 1) : (exp.last - 1)
                      : exp.last
        "(#{exp.first}:#{final_value})"
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
        infix = "#{op1}"
        puts infix
        rhs = R.rhs(R.as__formula("~ #{infix}"))
        R.enq(rhs)
        # Expression.new(parse_expression(args[0]))
      when 3
        op1 = parse_expression(args[0])
        op2 = parse_expression(args[2])
        puts op1
        puts op2
        
        optr = args[1].delete("`")
        formula = (optr == "~")? true : false
        infix = "#{op1} #{optr} #{op2}"
        puts infix
        
        rhs = R.rhs(R.as__formula("~ #{infix}"))
        R.enq(rhs)
        # Expression.new(infix, formula)
      else
        raise "Expressions can be build with either 1 or 3 arguments, got #{args.zie}"
      end
        
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    # private

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def initialize(infix, formula = false)
      @infix = infix
      @formula = formula
      @environment = R.list
    end

  end
  
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  class RExpression < Object
    
    #--------------------------------------------------------------------------------------
    # Builds 
    #--------------------------------------------------------------------------------------

    def self.build(expression)
      R.parse(text: expression.to_s)
    end
    
  end
  
end

#=========================================================================================
#
#=========================================================================================

module E

  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    
    params = []
    args.each do |arg|
      params << R::Expression.parse_expression(arg)
    end
    exp = "#{name}(#{params.join(", ")})"
    
    # rhs = R.rhs(R.as__formula("~ #{exp}"))
    # R.enq(rhs)
    
    R::Expression.new(exp)
  end
  
=begin
  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    R::Language.build(name, *args)
  end
=end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.[](executable)
    R::RubyCallback.build(executable)
  end

end
