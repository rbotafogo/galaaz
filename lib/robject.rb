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
    #
    #--------------------------------------------------------------------------------------

    def self.build(r_interop)

      # if the value is actually not an r_interop, then just return it: native Ruby
      # object
      if (!Truffle::Interop.foreign?(r_interop))
        return r_interop
      elsif (R.eval("is.atomic").call(r_interop))
        Vector.new(r_interop)
      elsif (R.eval("is.data.frame").call(r_interop))
        DataFrame.new(r_interop)
      elsif (R.eval("is.list").call(r_interop))
        List.new(r_interop)
      else # Generic type
        r_interop
      end
      
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing(symbol, *args)

      name = R.convert_symbol2r(symbol)
      
      if name =~ /(.*)=$/
        return
      end

      # no arguments: 2 options: either a named item of the object or apply the function
      # to the object
      if (args.length == 0)
        # if name is a named item of the object, then return the named item
        if (R.eval("`%in%`").call(name, R.eval("names").call(@r_interop))[0])
          return R::Object.build(R.double_subset.call(@r_interop, name))
        else
          # No, its not a named item, then apply the function 'name' to the object
          return R.eval(name).call(@r_interop)
        end
      end
      args.unshift(@r_interop)
      R.exec_missing(name, false, *args)
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
      R.exec_missing(name, false, *args)
    end
    
    #--------------------------------------------------------------------------------------
    # Calls the given r method (actual Interop object) on self (@r_interop) with args
    # @param method [Interop] R interop object pointing to a function
    # @param args [String] For now this is only a String argument.  Could be changed in
    # the future to deal with a list of arguments
    #--------------------------------------------------------------------------------------

    def callR(method, *args)
      R::Object.build(method.call(@r_interop, *args))
    end
    
    #--------------------------------------------------------------------------------------
    # Sets the current object self interop pointer to the returned value of the execution
    # of the given method with arguments. This method should be called when R will copy
    # the parameter, but in Ruby we want to hide the copying.
    # @param [Interop] Interop pointer to R function
    # @param [Array] Array of arguments 
    #--------------------------------------------------------------------------------------

    def setR(method, *args)
      @r_interop = method.call(@r_interop, *args)
      self
    end
    
    #--------------------------------------------------------------------------------------
    # Sets the names attribute of the object
    # @param [R::Object] names_vector is an RVector with the list of names.
    #--------------------------------------------------------------------------------------

    def names=(names_vector)
      # setR_override(R.set_attr, "names", names_vector.r_interop)
      # setR(R.eval("`attr<-`"), "names", names_vector.r_interop)
      R.exec_missing("`attr<-`", true, @r_interop, "names", names_vector)
    end

    def names
      # callR(R.get_attr, "names")
      callR(R.eval("names"))
    end
        
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def rclass=(class_name)
      # setR(R.set_attr, "class", class_name)
      setR(R.eval("`attr<-`"), "class", class_name)
      # R.exec_missing("`attr<-`", true, @r_interop, "class", class_name)
    end

    def rclass
      # callR(R.get_attr, "class")
      callR(R.eval("class"))
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def comment=(comment_text)
      # setR(R.set_attr, "comment", comment_text)
      R.exec_missing("`attr<-`", true, @r_interop, "comment", comment_text)
    end
    
    def comment
      # callR(R.get_attr, "comment")
      callR(R.eval("comment"))
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dim=(numeric_vector)
      setR(R.set_attr, "dim", numeric_vector.r_interop)
      # p "setting dim"
      # R.exec_missing("`dim<-`", true, @r_interop, numeric_vector)      
    end

    def dim
      # callR(R.get_attr, "dim")
      callR(R.eval("dim"))
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dimnames=(names_vector)
      # setR(R.set_attr, "dimnames", names_vector.r_interop)
      R.exec_missing("`attr<-`", true, @r_interop, "dimnames", names_vector)      
    end

    def dimnames
      # callR(R.get_attr, "dimnames")
      callR(R.eval("dimnames"))
    end
    
    #--------------------------------------------------------------------------------------
    # @bug Needed to create method R.row__names because dispatch is not working properly
    #--------------------------------------------------------------------------------------

    def row__names
      # callR(R.get_attr, "row.names")
      # callR(R.eval("row.names"))
      callR(R.get_row__names)
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
      # setR(R.set_attr, "tsp", numeric_vector.r_interop)
      R.exec_missing("`attr<-`", true, @r_interop, "tsp", numeric_vector)      
    end

    def tsp
      # callR(R.get_attr, "tsp")
      callR(R.eval("tsp"))
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


