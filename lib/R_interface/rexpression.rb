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
=begin
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
=end  
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
      params << R::Expression.parse_expression(arg)
    end
    exp = "#{name}(#{params.join(", ")})"
    
    # rhs = R.rhs(R.as__formula("~ #{exp}"))
    # R.enq(rhs)
    
    R::Expression.new(exp)
  end
  
#=begin
  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    R::Language.build(name, *args)
  end
#=end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.[](executable)
    R::RubyCallback.build(executable)
  end

end
=end
