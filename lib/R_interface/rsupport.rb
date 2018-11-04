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
  # The empty_symbol is necessary to represent indexing with a missing argument such
  # as [x, ].  What follows the ',' is an empty_symbol.  Whenever we use in Ruby the
  # :all symbol, it will be converted to an empty_symbol in R.
  #--------------------------------------------------------------------------------------
  
  @@empty_symbol = Polyglot.eval("R", <<-R)
    __missing_arg = quote(f(,0));
    __missing_arg[[2]]
  R

  def self.empty_symbol
    @@empty_symbol
  end

  # When evaluating to NA, Interop treats it as FALSE.  This breaks all expectations
  # about NA.  We need to protect NA from Interop unboxing.  Class NotAvailable
  # puts a list around NA, so that no unboxing occurs.
  @na = Polyglot.eval("R", <<-R)
    list(NA)
  R
  
  class NotAvailable < R::Object
  end

  NA = NotAvailable.new(@na)

  #--------------------------------------------------------------------------------------
  # This is a support module for evaluating R functions
  #--------------------------------------------------------------------------------------

  module Support

    # Using this method gives us more control over what happens when calling do.call
    # and allows for debugging.  Use it in exec_function when debugging is needed.
    @@exec_from_ruby = Polyglot.eval("R", <<-R)
      function(build_method, ...) {
        # print(build_method);
        # args = list(...);
        # print(args);
        res = do.call(...);
        # print(res);
        res2 = build_method(res);
        # print(res2);
        res2
      }
    R
    
    #----------------------------------------------------------------------------------------
    # Evaluates an R code
    # @param string [String] A string of R code that can be correctly parsed by R
    #----------------------------------------------------------------------------------------
    
    def self.eval(string)
      Polyglot.eval("R", string)
    end

    #----------------------------------------------------------------------------------------
    # @param object [Object] Any Ruby object
    # @return boolean if the object is an interop or not
    #----------------------------------------------------------------------------------------
    
    def self.interop(object)
      Truffle::Interop.foreign?(object)
    end

    #----------------------------------------------------------------------------------------
    # @param arg [Object] A Ruby object to be converted to R to be used by an R function, or
    # whatever needs it
    # @return Object that can be used in R
    #----------------------------------------------------------------------------------------

    def self.parse_arg(arg)
      
      case(arg)
      when Truffle::Interop
        arg
      when R::Object
        arg.r_interop
      when NegRange
        final_value = (arg.exclude_end?)? (arg.last - 1) : arg.last
        R::Support.eval("seq").call(arg.first, final_value)
      when Range
        final_value = (arg.exclude_end?)? (arg.last - 1) : arg.last
        R::Support.eval("seq").call(arg.first, final_value)
      when :all
        R.empty_symbol
      when Symbol
        arg = R::Support.eval("as.name").call(arg.to_s)
      when Proc, Method
        R::RubyCallback.build(arg)
      else
        arg
      end

    end
    
    #----------------------------------------------------------------------------------------
    # Parses the Ruby arguments into a R list of R objects
    # @param args [Ruby Parameter list]
    #----------------------------------------------------------------------------------------
    
    def self.parse2list(*args)
      
      params = Polyglot.eval("R", "list()")
      
      args.each_with_index do |arg, i|
        if (arg.is_a? Hash)
          arg.each_pair do |key, value|
            k = key.to_s.gsub(/__/,".")
            # HAS CHANGED IN RC6... FIX THIS TO THE NEW API
            # When evaluating to NA, Interop treats it as FALSE.  This breaks
            # all expectations about NA.  We need to protect NA from Interop
            # unboxing.  Class NotAvailable
            # puts a list around NA, so that no unboxing occurs.  We need to treat this
            # list here
            if (value.is_a? NotAvailable)
              # add the key as the name of the NA
              na_named = R::Support.eval("`names<-`").call(value.r_interop, k)
              params = R::Support.eval("c").call(params, na_named)
            else
              params = R::Support.eval("`[[<-`").
                         call(params, k, R::Support.parse_arg(value))
            end
          end
        elsif (arg.is_a? NotAvailable)
          params = R::Support.eval("c").call(params, arg.r_interop)
        else
          params = R::Support.eval("`[[<-`").
                     call(params, i+1, R::Support.parse_arg(arg))
        end
      end

      params
      
    end
    
    #----------------------------------------------------------------------------------------
    # Converts a Ruby symbol onto an R symbol.  Converts '__' to '.' and 'rclass' to
    # class
    # @param symbol [Symbol] A Ruby symbol to convert to R
    #----------------------------------------------------------------------------------------
    
    def self.convert_symbol2r(symbol)
      name = symbol.to_s
      # convert '__' to '.'
      name.gsub!(/__/,".")
      # Method 'rclass' is a substitute for R method 'class'.  Needed, as 'class' is also
      # a Ruby method on an object
      name.gsub!("rclass", "class")
      name
    end

    #----------------------------------------------------------------------------------------
    # Executes the given R function with the given arguments.
    #----------------------------------------------------------------------------------------
    
    def self.exec_function_i(function, *args)
      pl = R::Support.parse2list(*args)
      R::Support.eval("do.call").call(function, pl)
    end
    
    #----------------------------------------------------------------------------------------
    # @param function [R function (Interop)] R function to execute
    # @param internal [Boolean] true if returning to an internal object, i.e., does not
    # wrap the return object in a Ruby object
    # @args [Array] Array of arguments for the function
    #----------------------------------------------------------------------------------------
    
    def self.exec_function(function, *args)
      # function has no arguments, call it directly
      if (args.length == 0)
        return R::Object.build(function.call) # if args.length == 0
      end

      pl = R::Support.parse2list(*args)
      @@exec_from_ruby.call(R::Object.method(:build), function, pl)
      # R::Object.build(R::Support.eval("do.call").call(function, pl))
    end
    
    #----------------------------------------------------------------------------------------
    # @param function_name [String] Name of the R function to execute
    # @param internal [Boolean] true if returning to an internal object, i.e., does not
    # wrap the return object in a Ruby object
    # @args [Array] Array of arguments for the function
    #----------------------------------------------------------------------------------------
    
    def self.exec_function_name(function_name, *args)
      R::Support.exec_function(R::Support.eval(function_name), *args)
    end

    #----------------------------------------------------------------------------------------
    # sets the R symbol <name> to the given value
    # @param name [String] String representation of the R symbol that needs to be assigned
    # @param args [Array] Array with one object to be set to the symbol
    #----------------------------------------------------------------------------------------

    def self.set_symbol(name, *args)
      args << R::Support.eval("globalenv").call()
      R::Support.exec_function_name("assign", name, *args)
    end
    
    #----------------------------------------------------------------------------------------
    # Calls the R 'eval' function.  This requires some special semantics
    # R function 'eval' needs to be called in a special way, since it expects
    # the second argument to be an environment.  If the arguments are packed
    # into a list, then there is no second argument and the function fails to
    # use the second argument as environment
    #----------------------------------------------------------------------------------------

    def self.r_evaluate(*args)
      r_args = args.map { |arg| R::Support.parse_arg(arg) }
      R::Object.build(eval("eval").call(*r_args))
    end

    #----------------------------------------------------------------------------------------
    # Process the missing method
    # @param symbol [Symbol]
    # @param internal [Boolean] true if the method will return to an internal method, i.e.,
    # it should not wrap the return value inside an R::Object
    # @param object [Ruby Object] the ruby object to which the method is applied, false if
    # it is not applied to an object
    #----------------------------------------------------------------------------------------

    def self.process_missing(symbol, internal, *args)

      name = R::Support.convert_symbol2r(symbol)
      
      case name
      # missing method has an '=' sign in it...
      when ->(x) { x =~ /(.*)=$/ }
        R::Support.set_symbol($1, *args)
      # missing method is 'eval'... needs special treatment
      when "eval"
        R::Support.r_evaluate(*args)
      else
        function = R::Support.eval(name)
        internal ? R::Support.exec_function_i(function, *args) :
          R::Support.exec_function(function, *args)
      end
      
    end
    
    #----------------------------------------------------------------------------------------
    # Prints a foreign R interop pointer. Used for debug.
    #----------------------------------------------------------------------------------------

    def self.print_foreign(interop)
      puts "===External value==="
      R::Support.eval("print").call(interop)
      puts "===end external value==="
    end

    class << self
      alias :pf :print_foreign
    end
    
    #----------------------------------------------------------------------------------------
    #
    #----------------------------------------------------------------------------------------

  end
  
end

require_relative 'rsupport_scope'
