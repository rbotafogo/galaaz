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

  class List < Object
    include IndexedObject
    include Enumerable
    
    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def +(other_object)
      R::Support.exec_function_name("`+`", @r_interop, other_object.r_interop)
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def method_missing_assign(elmt_name, arg)
      setR_name("`[[<-`", elmt_name, arg)
    end

    #--------------------------------------------------------------------------------------
    # When indexing with '[' or '[[' an R object is returned.  Sometimes we need to have
    # access to an umboxed Ruby element, for instance, in an numeric array, we might want
    # to receive the actual number that can be used in a Ruby method.  In this case, we
    # use the '<<' operator.
    # @return the Ruby element at the given index in the vector
    #--------------------------------------------------------------------------------------

    def >>(index)
      raise IndexError.new("index #{index} out of list bounds: 0...#{index - 1}") if
        (index > (length - 1) >> 0)
      raise ArgumentError.new("Indexed element is not a vector") if
        !self[[index + 1]].is_a? R::Vector
      return nil if (self[[index + 1]].is__null >> 0)
      self[[index + 1]] >> 0
    end

    #--------------------------------------------------------------------------------------
    # Each cannot return a Enumerator because R is single threaded.  When this restriction
    # is removed, make each return self.to_enum
    #--------------------------------------------------------------------------------------

    def each

      # length is a R::Vector, in order to extract its size as a Ruby number we need to
      # use the >> operator
      (1..length >> 0).each do |i|
        yield self[[i]]
      end
      
    end

    #--------------------------------------------------------------------------------------
    # Need to override each_with_index, as R indexing starts at 1
    #--------------------------------------------------------------------------------------

    def each_with_index
      
      (1..length >> 0).each do |i|
        yield self[[i]], i
      end
      
    end
    
  end
  
  
end

