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

    def self.build(r_interop)
      # if the value is actually not an r_interop, then just return it: native Ruby
      # object
      if (!Truffle::Interop.foreign?(r_interop))
        return r_interop
      elsif (R.is__atomic(r_interop)) # || R.is__list(r_interop))
        Vector.new(r_interop)
      elsif (R.is__list(r_interop))
        List.new(r_interop)
      else
        Generic.new(r_interop)
      end
      
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing(symbol, *args)

      name = symbol.to_s
      # convert '__' to '.'
      name.gsub!(/__/,".")

      # R does not support methods on objects.  However, in order to use idiomatic Ruby
      # a call to a method on an RObject will be converted to a method call on the object.
      params = R.parse(*args)
      R::Object.build(R.eval(name).call(@r_interop, *params))
      
    end
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def names=(names_vector)
      @@set_attr.call(@r_interop, "names", names_vector.r_interop)
    end

    def class=(class_name)
      @@set_attr.call(@r_interop, "class", class_name)
    end
    
    def comment=(comment_text)
      @@set_attr.call(@r_interop, "comment", comment_text)
    end

    def dim=(numeric_vector)
      @@set_attr.call(@r_interop, "dim", numeric_vector.r_interop)
    end

    def dimnames=(names_vector)
      @@set_attr.call(@r_interop, "dimnames", names_vector.r_interop)
    end

    def row__names=(names_vector)
      @@set_attr.call(@r_interop, "row.names", names_vector.r_interop)
    end
      
    def tsp=(numeric_vector)
      @@set_attr.call(@r_interop, "tsp", numeric_vector.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def to_s
      @r_interop.to_s
    end
    
  end


  class Generic < Object

  end

end

require_relative 'rvector'

