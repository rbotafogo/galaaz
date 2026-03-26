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
    # Unbox list to Ruby. Recurses until only Ruby values (no R::Object in result).
    # - index.nil? → whole list → Array of unboxed elements (single list → [x]).
    # - index i   → list[[i+1]] unboxed (one Ruby value).
    # Raises R::UnboxDepthError when recursion exceeds MAX_UNBOX_DEPTH (can be expensive).
    #--------------------------------------------------------------------------------------
    def unboxed_get(index = nil, depth = 0)
      if depth >= ::R::Support::MAX_UNBOX_DEPTH
        ::Kernel.raise(::R::UnboxDepthError, "unbox: list too deep (max depth #{::R::Support::MAX_UNBOX_DEPTH} exceeded)")
      end
      # NewBridge hardening path: use structural bridge reads during recursion.
      if ::R.bridge.respond_to?(:unbox_list_length) && ::R.bridge.respond_to?(:unbox_list_element)
        n = ::R.bridge.unbox_list_length(@r_interop)
        if index.nil?
          return [] if n <= 0
          arr = []
          (1..n).each do |i|
            elt = ::R.bridge.unbox_list_element(@r_interop, i)
            if elt.nil?
              arr << nil
            elsif !elt.is_a?(::R::Object)
              arr << elt
            else
              arr << elt.unboxed_get(nil, depth + 1)
            end
          end
          return arr
        end

        bound = n - 1
        ::Kernel.raise(::IndexError.new("index #{index} out of list bounds: 0...#{bound}")) if index > bound
        elt = ::R.bridge.unbox_list_element(@r_interop, index + 1)
        return elt unless elt.is_a?(::R::Object)
        return nil if elt.nil?
        return nil if elt.respond_to?(:rclass) && elt.rclass.to_s.strip == 'NULL'
        return elt.unboxed_get(nil, depth + 1)
      end

      if index.nil?
        # Whole list → Array of unboxed elements (recurse into each element).
        len_val = length
        n = len_val.is_a?(::R::Vector) ? len_val.unboxed_get(0) : len_val
        n = n.to_i if n.respond_to?(:to_i)
        return [] unless n.is_a?(::Integer) && n >= 1
        arr = []
        (1..n).each do |i|
          elt = self[[ [i] ]]
          if elt.nil?
            arr << nil
          elsif !elt.is_a?(::R::Object)
            arr << elt
          else
            arr << (elt.is__null.unboxed_get(0) ? nil : elt.unboxed_get(nil, depth + 1))
          end
        end
        return arr
      end

      # Single element at index
      bound_val = length
      bound = bound_val.is_a?(::R::Vector) ? bound_val.unboxed_get(0) : bound_val
      bound = bound.to_i - 1 if bound.respond_to?(:to_i)
      bound = 0 if bound.nil? || !bound.is_a?(::Integer) || bound < 0
      ::Kernel.raise(::IndexError.new("index #{index} out of list bounds: 0...#{bound}")) if index > bound
      elt = self[[ [index + 1] ]]
      return elt unless elt.is_a?(::R::Object)
      return nil if (elt.is__null.respond_to?(:unboxed_get) ? elt.is__null.unboxed_get(0) : elt.is__null)
      elt.unboxed_get(nil, depth + 1)
    end

    def >>(index)
      # Count the list root as depth 1 so MAX_UNBOX_DEPTH applies to list nesting
      # the same way legacy unboxing specs expect.
      unboxed_get(index, 1)
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

