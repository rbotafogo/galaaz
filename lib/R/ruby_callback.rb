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

  class RubyCallback

    # The Ruby Proc, Method (or Object?) to be called back
    attr_reader :object
    # The R function that will call back on the object
    attr_reader :r_function

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def self.build(object)
      RubyCallback.new(object).r_function
    end
    
    #--------------------------------------------------------------------------------------
    # Initializes a callback object and constructs the R function that calls back the
    # object.  RubyCallback class will act as proxy to the actual Ruby Object since it
    # needs to deal with R parameters and Return values boxing and unboxing when needed
    # @param object [Object] Ruby Object
    #--------------------------------------------------------------------------------------

    def initialize(object)
      @object = object
      
      # ruby_callback_method is a method that returns an R function that returns an R
      # function that calls back this object callback method (look at callback bellow)
      @r_function = R::Support.ruby_callback_method.call(method(:callback))
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing(symbol, *args)
      p "in ruby_callback.rb method missing with #{symbol} #{args}"
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def callback(*args)

      # converts every arg into a R::Object (Ruby object that wraps an R Interop)
      args.map! { |arg| R::Object.build(arg) }
      
      # calls the callback method and convert the result back to an R object
      # method parse_arg was developed to parse the arguments to an R function
      # but in a callback the return value needs to be converted.  In this case
      # the name parse_arg is misleading
      R::Support.parse_arg(@object.call(*args))
      
    end
    
  end
  
end
