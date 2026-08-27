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
    # Unbox vector to Ruby. Atomic vectors: length 1 → scalar, length > 1 → Array of scalars.
    # Recursion depth is checked; vectors do not recurse into R::Object (elements are scalars).
    #--------------------------------------------------------------------------------------
    def unboxed_get(index = nil, depth = 0)
      if depth >= ::R::Support::MAX_UNBOX_DEPTH
        ::Kernel.raise(::R::UnboxDepthError, "unbox: list too deep (max depth #{::R::Support::MAX_UNBOX_DEPTH} exceeded)")
      end
      if index.nil?
        arr = ::R.bridge.pull_vector(@r_interop)
        return (arr.length == 1 ? arr[0] : arr)
      end

      # For indexed unboxing, use binary transport + result protocol (no printed-text parsing).
      idx = index
      len = atomic_vector_length
      ::Kernel.raise(::IndexError.new("index #{idx} out of array bounds: 0...#{len - 1}")) if idx >= len

      type = atomic_vector_typeof

      case type
      when 'integer'
        data = ::R.bridge.pull_integer_vector(@r_interop, 1, idx, 1)
        data[0]
      when 'character'
        var_name = ::R::Support.generate_var_name
        assignment = "#{var_name} <- #{@r_interop}[[#{idx + 1}]]"
        envelope = ::R.bridge.eval_r_with_result(assignment)
        raise "Result protocol: no envelope for character element #{@r_interop}[[#{idx + 1}]]" unless envelope
        raise "Result protocol: expected scalar_character, got #{envelope[:type]}" unless envelope[:type] == :scalar_character
        v = envelope[:value]
        (v.is_a?(::String) && v =~ /^rb_obj_\d+$/) ? ::R::Support.get_ruby_object(v) : v
      when 'logical'
        var_name = ::R::Support.generate_var_name
        assignment = "#{var_name} <- #{@r_interop}[[#{idx + 1}]]"
        envelope = ::R.bridge.eval_r_with_result(assignment)
        raise "Result protocol: no envelope for logical element #{@r_interop}[[#{idx + 1}]]" unless envelope
        raise "Result protocol: expected scalar_logical, got #{envelope[:type]}" unless envelope[:type] == :scalar_logical
        case envelope[:value]
        when true then true
        when false then false
        else nil
        end
      else
        data = ::R.bridge.pull_double_vector(@r_interop, 1, idx, 1)
        data[0]
      end
    end

    alias_method :>>, :unboxed_get
    alias_method :<<, :unboxed_get

    # Return Ruby array so RSpec/eq and array conversion don't forward to_ary to R.
    # Must always return an Array (length-1 vector unboxes to scalar via >> nil, so wrap in [v]).
    def to_ary
      v = self >> nil
      v.is_a?(::Array) ? v : [v]
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
      len = atomic_vector_length

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

    # CRuby Enumerable#sum probes begin/end (range fast-path). R::Object#respond_to?
    # always returns true, so that probe would hit method_missing and call R's begin.
    # Implement sum in Ruby so MRI matches JRuby Enumerable behavior for blocks;
    # without a block, forward to R's sum via method_missing.
    def sum(*args, &block)
      if block
        ::Kernel.raise(::ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..1)") if args.size > 1
        acc = args.empty? ? 0 : args[0]
        each { |el| acc = acc + block.call(el) }
        acc
      else
        method_missing(:sum, *args)
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
      ::Kernel.raise(::NotImplementedError, "R::Vector#<=> is not implemented")
    end

    private

    # Length via result protocol (scalar assignment envelope), not printed `[1] n` text.
    def atomic_vector_length
      var_name = ::R::Support.generate_var_name
      env = ::R.bridge.eval_r_with_result("#{var_name} <- length(#{@r_interop})")
      raise "Result protocol: no envelope for length(#{@r_interop})" unless env
      case env[:type]
      when :scalar_integer
        env[:value].to_i
      when :scalar_double
        env[:value].to_i
      else
        raise "Result protocol: expected scalar length, got #{env[:type].inspect}"
      end
    end

    # R typeof() as string via result protocol.
    def atomic_vector_typeof
      var_name = ::R::Support.generate_var_name
      env = ::R.bridge.eval_r_with_result("#{var_name} <- typeof(#{@r_interop})")
      raise "Result protocol: no envelope for typeof(#{@r_interop})" unless env
      raise "Result protocol: expected scalar_character for typeof, got #{env[:type]}" unless env[:type] == :scalar_character
      env[:value].to_s
    end

  end
  
end

