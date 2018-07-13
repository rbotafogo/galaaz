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

require_relative 'r_methods'

module R
  
  class Object

    attr_reader :r_interop
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      @r_interop = r_interop
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def pp
      R.print.call(@r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def as__data__frame
      R.as__data__frame.call(@r_interop)
    end

    #--------------------------------------------------------------------------------------
    # @bug
    # @param r_interop [Interop] pointer to an R object
    # @return the R object wrapped in a Ruby class
    #--------------------------------------------------------------------------------------

    def self.build(r_interop)

      # if the value is actually not an r_interop, then just return it: native Ruby
      # object
      if (!Truffle::Interop.foreign?(r_interop))
        return r_interop
      elsif (R.eval("is.atomic").call(r_interop))
        # Something is wrong here... sometimes we get a vector and sometimes we
        # get a scalar.  If the vector has only 1 element, then return the first
        # element.  This should be fixed.  I think it is a bug in graalvm/Interop
        (R.eval("length").call(r_interop) == 1) ? r_interop[0] : Vector.new(r_interop)
        # Vector.new(r_interop)
      elsif (R.eval("is.data.frame").call(r_interop))
        DataFrame.new(r_interop)
      elsif (R.eval("is.list").call(r_interop))
        List.new(r_interop)
      else # Generic type
        r_interop
      end

    end
    
    #--------------------------------------------------------------------------------------
    # @bug
    #--------------------------------------------------------------------------------------

    def method_missing(symbol, *args)

      name = R.convert_symbol2r(symbol)
      
      if name =~ /(.*)=$/
        # do something
        return
      end

      # no arguments: 2 options: either a named item of the object or apply the function
      # to the object
      if (args.length == 0)
        # if name is a named item of the object, then return the named item.  Here also
        # we sometimes get an vector and sometimes a scalar.  Have to check which it is.
        named = R.eval("`%in%`").call(name, R.eval("names").call(@r_interop))
        if (true === named || named[0])
          return R.exec_function_name("`[[`", @r_interop, name)
        else
          # No, its not a named item, then apply the function 'name' to the object
          # return R.eval(name).call(@r_interop)
          return R.exec_function_name(name, @r_interop)
        end
      end
      args.unshift(@r_interop)
      R.exec_function_name(name, *args)
      
    end

    #----------------------------------------------------------------------------------------
    # We use the following notation to access binary R functions such as %in%:
    # R.vec_ "in", list.
    # @param args [Array] The first element of the array is an R infix function, the other
    # arguments are the list of arguments for the function.
    #----------------------------------------------------------------------------------------

    def _(*args)
      name = "`%#{args.shift.to_s}%`"
      args.unshift(@r_interop)
      R.exec_function_name(name, *args)
    end
    
    #--------------------------------------------------------------------------------------
    # Sets the current object self interop pointer to the returned value of the execution
    # of the given method with arguments. This method should be called when R will copy
    # the parameter, but in Ruby we want to hide the copying.
    # @param [Interop] Interop pointer to R function
    # @param [Array] Array of arguments 
    #--------------------------------------------------------------------------------------

    def setR(method, *args)
      @r_interop = R.exec_function_i(method, @r_interop, *args)
      self
    end
    
    #--------------------------------------------------------------------------------------
    # Sets the names attribute of the object
    # @param [R::Object] names_vector is an RVector with the list of names.
    #--------------------------------------------------------------------------------------

    def names=(names_vector)
      setR(R.eval("`names<-`"), names_vector)      
    end

    def names
      R.exec_function_name("names", @r_interop)
    end
        
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def rclass=(class_name)
      setR(R.eval("`class<-`"), class_name)
    end

    def rclass
      R.exec_function_name("class", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def comment=(comment_text)
      setR(R.eval("`comment<-`"), comment_text)      
    end
    
    def comment
      R.exec_function_name("comment", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dim=(numeric_vector)
      setR(R.eval("`dim<-`"), numeric_vector)
    end

    def dim
      R.exec_function_name("dim", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dimnames=(names_vector)
      setR(R.eval("`dimnames<-`"), names_vector)
    end

    def dimnames
      R.exec_function_name("dimnames", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    # @bug Needed to create method R.row__names because dispatch is not working properly
    #--------------------------------------------------------------------------------------

    def row__names
      R.exec_function(R.get_row_names, @r_interop)
    end

    def set_row_names
      R.eval(<<-R)
      function(object, x) {
        row.names(object) <- x;
        object
        }
      R
    end

    # since we need to call a method and the method changes the object, then we need to
    # change our internal pointer also @r_interop.  Ideally, just setting the row.names
    # should work.
    def row__names=(names_vector)
      @r_interop = set_row_names.call(@r_interop, names_vector.r_interop)
      self
    end
      
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def tsp=(numeric_vector)
      # setR(R.eval("`attr<-`"), "tsp", numeric_vector)
      setR(R.eval("`tsp<-`"), numeric_vector)
    end

    def tsp
      R.exec_function_name("tsp", @r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def attr=(which: w, value: v)
      value = (R.interop(value) ? value.r_interop : value)
      setR(R.set_attr, which, value)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def to_s
      @r_interop.to_s
    end
    
  end

end


