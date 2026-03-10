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

  class Vector < Object
    include IndexedObject
    include BinaryOperators
    include ExecBinOp
    include UnaryOperators
    include ExecUniOp
    include LogicalOperators
    include ::Enumerable

    def class
      ::R::Vector
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def initialize(r_interop)
      super(r_interop)
    end
    
    #--------------------------------------------------------------------------------------
    # When indexing with '[' or '[[' an R object is returned.  Sometimes we need to have
    # access to an umboxed Ruby element, for instance, in an numeric array, we might want
    # to receive the actual number that can be used in a Ruby method.  In this case, we
    # use the '>>' operator.
    # @return the Ruby element at the given index in the vector
    #--------------------------------------------------------------------------------------

    def unboxed_get(index = nil)
      if index.nil?
        # Unbox whole vector to Ruby array
        return ::R.bridge.pull_vector(@r_interop)
      end

      # For indexed unboxing, use binary transport
      idx = index
      len_raw = ::R.bridge.eval_r("length(#{@r_interop})")
      m = len_raw.match(/\[1\] (.*)/)
      len = m ? m[1].to_i : 0

      ::Kernel.raise(::IndexError.new("index #{idx} out of array bounds: 0...#{len-1}")) if
        (idx >= len) 
      
      # Determine type
      type_raw = ::R.bridge.eval_r("typeof(#{@r_interop})")
      type = type_raw.match(/\[1\] \"(.*)\"/)[1] rescue "double"
      
      if type == 'integer'
        data = ::R.bridge.pull_integer_vector(@r_interop, 1, idx, 1)
      else
        data = ::R.bridge.pull_double_vector(@r_interop, 1, idx, 1)
      end
      data[0]
    end

    alias_method :>>, :unboxed_get

    # Return Ruby array so RSpec/eq and array conversion don't forward to_ary to R
    def to_ary
      self >> nil
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def pop
      # Return unboxed first element as a Ruby scalar
      unboxed_get(0)
    end
    
    CHUNK_SIZE = 1_000_000 # 1M rows per page

    def stitch(halo: 0, &block)
      # 1. Get length
      len_raw = ::R.bridge.eval_r("length(#{@r_interop})")
      len = len_raw.match(/\[1\] (.*)/)[1].to_i
      
      # 2. Allocate result vector in R
      res_name = ::R::Support.generate_var_name
      ::R.bridge.eval_r("#{res_name} <- numeric(#{len})")

      # 3. Process in chunks with Halo
      offset = 0
      while offset < len
        current_chunk_size = [CHUNK_SIZE, len - offset].min
        
        # Calculate extended range for Halo
        # R indices start at 1, but pull_double_vector uses 0-based offset
        pull_offset = [0, offset - halo].max
        pull_end = [len, offset + current_chunk_size + halo].min
        actual_pull_size = pull_end - pull_offset
        
        # 3.1 Pull chunk with Halo
        data = ::R.bridge.pull_double_vector(@r_interop, len, pull_offset, actual_pull_size)
        
        # 3.2 Process in Ruby
        # The block receives the data with halo. 
        # It's up to the block to handle the context, 
        # but the result should be the same size as data.
        result_data_with_halo = block.call(data)
        
        # 3.3 Extract the "inner" part (discard halo results)
        # The offset of our chunk within the pulled data is (offset - pull_offset)
        inner_start = offset - pull_offset
        inner_result = result_data_with_halo[inner_start, current_chunk_size]
        
        # 3.4 Push only the inner chunk back to R
        ::R.bridge.push_double_vector(inner_result, res_name, offset, len)
        
        offset += current_chunk_size
      end
      
      # 4. Return as R::Object (wrapped as Vector)
      ::R::Object.build(res_name)
    end

    def map(&block)
      stitch(halo: 0) do |data|
        data.map(&block)
      end
    end

    def each(mode = :vec)
      case mode
      when :vec
        (1..length.unboxed_get(0)).each do |i|
          yield self[i]
        end
      when :native
        (0...length.unboxed_get(0)).each do |i|
          yield unboxed_get(i)
        end
      else
        ::Kernel.raise("Type #{mode.inspect} is unknown for method :each")
      end
    end

    #--------------------------------------------------------------------------------------
    # Need to override each_with_index, as R indexing starts at 1
    #--------------------------------------------------------------------------------------

    def each_with_index(result = :vec)
      case result
      when :vec
        (1..length.unboxed_get(0)).each do |i|
          yield self[i], i
        end
      when :native
        (0...length.unboxed_get(0)).each do |i|
          yield unboxed_get(i), i
        end
      else
        ::Kernel.raise("Type #{result} is unknown for method :each")
      end
      
    end
    
    #--------------------------------------------------------------------------------------
    # @TODO: SHOULD DEFINE COMPARISON BETWEEN TWO VECTORS
    #--------------------------------------------------------------------------------------

    def <=>(other_vector)
      puts "comparison called"
    end

  end
  
end

