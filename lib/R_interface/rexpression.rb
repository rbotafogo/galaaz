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
  
  class Expression
    include BinaryOperators
    include ExpBinOp
    
    attr_reader :infix
    attr_reader :prefix
    attr_reader :formula
        
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

    def self.check_operator(op)
      raise "Operand #{op} should be of type Symbol, Expression or Numeric, but  got #{op.class}" if
        !((op.is_a? Symbol) || (op.is_a? R::Expression) || (op.is_a? Numeric))
    end
    
    #--------------------------------------------------------------------------------------
    # Build a new expression from the given argument.
    # @param args [Array] size of array should be either 1 or 3.  When 3, then it is of
    #   the form '<operand> <binary operator> <operand>'
    #--------------------------------------------------------------------------------------
    
    def self.build(*args)

      case args.size
      when 1
        check_operator(args[0])
        if ((args[0].is_a? Symbol) || (args[0].is_a? Numeric))
          return Expression.new(args[0].to_s, args[0].to_s)
        end
        Expression.new(args[0].infix, args[0].prefix)
      when 3
        check_operator(args[0])
        check_operator(args[2])
        
        pre0 = (args[0].is_a? R::Expression)? args[0].prefix : args[0]
        pre2 = (args[2].is_a? R::Expression)? args[2].prefix : args[2]
        optr = args[1].delete("`")
        formula = (optr == "~")? true : false
        
        infix = "(#{args[0]} #{optr} #{args[2]})"
        prefix = "#{optr} #{pre0} #{pre2}"

        Expression.new(infix, prefix, formula)
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
    
    def initialize(infix, prefix, formula = false)
      @infix = infix
      @prefix = prefix
      @formula = formula
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

module Q

  def self.parse_params(*args)

    params = []

    args.each do |arg|
      case arg
      when Hash
        arg.each_pair do |key, value|
          k = key.to_s.gsub(/__/,".")
          params << "#{key} = #{value}"
        end
      when R::NotAvailable
        params << "na"
      when NegRange
        # final_value = (arg.exclude_end?)? (arg.last - 1) : arg.last
        params << "-(#{arg.first}:#{arg.last})"
      when Range
        final_value = (arg.exclude_end?)? (arg.first > arg.last)?
                        (arg.last + 1) : (arg.last - 1)
                      : arg.last
        params << "(#{arg.first}:#{final_value})"
      when :all
        params << "."
      else
        params << arg.to_s
      end

    end
          
    params.join(", ")
        
  end
  
  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    rargs = parse_params(*args)
    exp = "#{name}(#{rargs})"
    R::Expression.new(exp, exp)
  end
  
end
