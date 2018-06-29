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
  
  class Object
    
    @@set_attr = Polyglot.eval("R", <<-R)
      function(object, which, value) {
        attr(object, which) = value
      }
    R

    @@get_attr = Polyglot.eval("R", "attr")

    # define a function to access the subset '[' method
    @@subset = Polyglot.eval("R", <<-R)
      function(object, index) {
        return(object[index])
      }
    R

    @@double_subset = Polyglot.eval("R", <<-R)
      function(object, index) {
        return(object[[index]])
      }
    R
    
    @@subset_assign = Polyglot.eval("R", "`[<-`")
    @@dbk_assign = Polyglot.eval("R", "`[[<-`")

    @@print = Polyglot.eval("R", "function(x) print(x)")

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

    def callR(method, *args)
      R::Object.build(method.call(@r_interop, *args))
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
      elsif (R.eval("is.list").call(r_interop))
        List.new(r_interop)
      elsif (R.eval("is.data.frame").call(r_interop))
        DataFramen.new(r_interop)
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
        if (R.eval("`%in%`").call(name, R.eval("names").call(@r_interop)))
          return R::Object.build(@@double_subset.call(@r_interop, name))
        else
          # No, its not a named item, then apply the function 'name' to the object
          return R.eval(name).call(@r_interop)
        end
      end
      args.unshift(@r_interop)
      R.exec_missing(name, false, *args)
    end
      
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def names
      callR(@@get_attr, "names")
    end
    
    def names=(names_vector)
      callR(@@set_attr, "names", names_vector.r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def rclass
      callR(@@get_attr, "class")
    end

    def rclass=(class_name)
      callR(@@set_attr, "class", class_name)
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def comment
      callR(@@get_attr, "comment")
    end
    
    def comment=(comment_text)
      callR(@@set_attr, "comment", comment_text)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dim
      callR(@@get_attr, "dim")
    end
    
    def dim=(numeric_vector)
      callR(@@set_attr, "dim", numeric_vector.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def dimnames
      callR(@@get_attr, "dimnames")
    end
    
    def dimnames=(names_vector)
      callR(@@set_attr, "dimnames", names_vector.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def row__names
      callR(@@get_attr, "row.names")
    end
    
    def row__names=(names_vector)
      callR(@@set_attr, "row.names", names_vector.r_interop)
    end
      
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def tsp
      callR(@@get_attr, "tsp")
    end
    
    def tsp=(numeric_vector)
      callR(@@set_attr, "tsp", numeric_vector.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def attr=(which: w, value: v)
      value = (R.interop(value) ? value.r_interop : value)
      callR(@@set_attr, which, value)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def to_s
      @r_interop.to_s
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def pp
      @@print.call(@r_interop)
    end

  end

end


