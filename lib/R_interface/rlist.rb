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
    include ::Enumerable

    def class
      ::R::List
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------
    
    def +(other_object)
      ::R::Support.exec_function_name("`+`", @r_interop, other_object.r_interop)
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
      if index.nil?
        # Unbox single element for == comparison (e.g. expect(list).to eq val)
        len = length
        len = len.is_a?(::R::Vector) ? len.unboxed_get(0) : len
        return self unless len.is_a?(::Integer) && len == 1
        elt = self[[ [1] ]]
        return elt unless elt.is_a?(::R::Object)
        return nil if (elt.is__null.respond_to?(:unboxed_get) ? elt.is__null.unboxed_get(0) : elt.is__null)
        return elt.is_a?(::R::Vector) ? elt.unboxed_get(0) : elt
      end
      bound = length
      bound = bound.is_a?(::R::Vector) ? bound.unboxed_get(0) : bound
      bound = bound.is_a?(::Integer) ? bound - 1 : 0
      bound = 0 if bound.nil? || bound < 0
      ::Kernel.raise(::IndexError.new("index #{index} out of list bounds: 0...#{bound}")) if index > bound
      elt = self[[ [index + 1] ]]
      # list[[i]] can return unboxed scalar (Integer, Float, etc.) when protocol unboxes length-1
      return elt unless elt.is_a?(::R::Object)
      ::Kernel.raise(::ArgumentError.new("Indexed element is not a vector")) unless elt.is_a?(::R::Vector)
      null_check = elt.is__null
      return nil if (null_check.respond_to?(:unboxed_get) ? null_check.unboxed_get(0) : null_check)
      elt.unboxed_get(0)
    end

    #--------------------------------------------------------------------------------------
    # Each cannot return a Enumerator because R is single threaded.  When this restriction
    # is removed, make each return self.to_enum
    #--------------------------------------------------------------------------------------

    def each

      len = length
      len = len.is_a?(::R::Vector) ? len.unboxed_get(0) : len
      (1..len).each do |i|
        # In Ruby list[[i]] is list.[]( [i] ) → single Array arg → we use R's [[ (element)
        yield self[[ [i] ]]
      end

    end

    #--------------------------------------------------------------------------------------
    # Need to override each_with_index, as R indexing starts at 1
    #--------------------------------------------------------------------------------------

    def each_with_index

      len = length
      len = len.is_a?(::R::Vector) ? len.unboxed_get(0) : len
      (1..len).each do |i|
        yield self[[ [i] ]], i
      end

    end    
  end
  
  
end

