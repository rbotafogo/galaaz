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

module E

  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param args [Array] arguments to the missing method
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    R::Language.new(name, *args)
  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.[](executable)
    R::RubyCallback.build(executable)
  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  class Expression
    attr_reader :expression

    #----------------------------------------------------------------------------------------
    #
    #----------------------------------------------------------------------------------------

    def initialize(expression_string)
      @expression = expression_string
    end

    #--------------------------------------------------------------------------------------
    # Parses the expression and returns an Interop with the parsed expression.  This
    # method should not, in principle, be called by the final user.
    # @return [Interop] pointer
    #--------------------------------------------------------------------------------------

    def parse
      R.parse(text: @expression).r_interop
    end
    
    #--------------------------------------------------------------------------------------
    # Prepares the expression for evaluation by the receiving function.  This has to be
    # a quoted, eval expression.  If, for instance, the expression is (cyl ~ disp), then
    # qeval will return eval(cyl ~ disp).  This method should not, in principle, be
    # called by the final user.
    # @return [Interop] pointer
    #--------------------------------------------------------------------------------------

    def qeval
      R::Support.eval("quote(#{@expression})")
=begin      
      if !@expression.include? "~"
        R::Support.eval("quote(#{@expression})")
      else
        R::Support.eval("call").call("eval", parse)
      end
=end      
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def to_s
      @expression.to_s
    end
    
  end

end

