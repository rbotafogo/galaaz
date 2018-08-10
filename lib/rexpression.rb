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

  #--------------------------------------------------------------------------------------
  # This class represents a language expression
  #--------------------------------------------------------------------------------------
  
  class Language
    
    #----------------------------------------------------------------------------------------
    # @param function_name [String] R function name from which to build an expression
    # @param args [Array] Array of arguments for the function
    #----------------------------------------------------------------------------------------
    
    def self.build_function(function_name, *args)
      # func = R::Support.eval(function_name)
      # pl = R::Support.parse2list(R::Support.eval(function_name),
      # *args)
      R::Support.eval("as.call").
        call(R::Support.parse2list(R::Support.eval(function_name), *args))
    end
    
  end
  
  #----------------------------------------------------------------------------------------
  # @param symbol [Symbol]
  # @param object [Ruby Object] the ruby object to which the method is applied, false if
  # it is not applied to an object
  #----------------------------------------------------------------------------------------
  
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    E::Language.build_function(name, *args)
  end
  
end
