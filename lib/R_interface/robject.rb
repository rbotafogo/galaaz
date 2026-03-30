# robject.rb
#
# R::Object is the Ruby proxy for an R value. It inherits from BasicObject so that most
# method calls (e.g. .dim, .names, .length) are forwarded to R via method_missing.
#
# Each instance holds @r_interop (the R-side handle, e.g. "g2_v42") and optionally
# @expression (source expression for Language objects). Object.build(...) turns a handle
# into the appropriate subclass: DataFrame, Matrix, Vector, List, Closure, RSymbol,
# RExpression, or a plain Object for other R types. Handles "rb_obj_*" are unwrapped
# to the stored Ruby object; R NULL becomes Ruby nil.
#
require_relative 'r_methods'

module R
  class Object < BasicObject
    include IndexedObject
    include BinaryOperators
    include ExecBinOp
    include UnaryOperators
    include ExecUniOp

    # Methods we explicitly define (Phase A / BasicObject). respond_to?(sym) is true for these and for any symbol we forward to R.
    EXPLICIT_RUBY_SURFACE = [
      :r_interop, :expression, :expression=,
      :[], :[]=, :>>, :unboxed_get, :to_ruby, :to_i, :to_ary, :length, :size,
      :class, :to_s, :rclass, :typeof, :inspect, :object_id, :__id__,
      :==, :equal?, :call, :nil?, :pretty_print,
      :instance_variable_set, :instance_variable_get,
      :is_a?, :kind_of?, :instance_of?, :respond_to?,
      :method_missing
    ].freeze

    attr_reader :r_interop
    attr_accessor :expression

    # Delegate to Kernel#instance_variable_set so that instance vars work despite BasicObject.
    def instance_variable_set(name, value)
      ::Object.instance_method(:instance_variable_set).bind(self).call(name, value)
    end

    # Delegate to Kernel#instance_variable_get so that instance vars work despite BasicObject.
    def instance_variable_get(name)
      ::Object.instance_method(:instance_variable_get).bind(self).call(name)
    end

    # R objects are never nil; R NULL is converted to Ruby nil in Object.build.
    def nil?
      false
    end

    # Used by pp/inspect-style pretty printing.
    def pretty_print(pp)
      pp.text(inspect)
    end

    def initialize(r_interop, expression = nil)
      @r_interop = r_interop
      @expression = expression
    end

    # Factory: build the right Ruby wrapper for an R value. Returns a subclass (DataFrame, Vector, etc.),
    # or the unwrapped Ruby value for rb_obj_* handles and for R NULL. Pass r_class to avoid an R class() call.
    def self.build(r_interop, expression = nil, r_class: nil)
      # Ruby object handles stored in R: unwrap to the original Ruby object.
      if r_interop.is_a?(::String) && r_interop.start_with?("rb_obj_")
        return ::R::Support.get_ruby_object(r_interop)
      end

      # If we got a basic Ruby type, it's already unboxed
      return r_interop if r_interop.is_a?(::Numeric) || r_interop.is_a?(::TrueClass) ||
                         r_interop.is_a?(::FalseClass) || r_interop.nil? || r_interop.is_a?(::Symbol)

      if r_interop.is_a?(::String) && r_interop.start_with?("g2_v")
        return new(r_interop, expression) unless ::R.bridge.ready?

        begin
          r_class_arg = r_class
          r_class = r_class.to_s.strip
          r_class = nil if r_class.nil? || r_class.empty?
          r_class ||= ::R.bridge.eval_r("paste(class(#{r_interop}), collapse=' ')").gsub(/^\[1\] /, "").gsub(/"/, "").strip
          # R NULL -> Ruby nil so we never call >> or other methods on a NULL handle (which can crash R)
          return nil if r_class.to_s.strip == "NULL"
          if ::ENV['GALAAZ_DEBUG']
            ::Kernel.puts "DEBUG: Object.build r_interop=#{r_interop.inspect} r_class_arg=#{r_class_arg.inspect} r_class=#{r_class.inspect}"
          end
          obj = case
                when r_class.include?("data.frame") || r_class.include?("tbl_df")
                  ::R::DataFrame.new(r_interop, expression)
                when r_class.include?("matrix") || r_class.include?("array")
                  ::R::Matrix.new(r_interop, expression)
                when r_class.include?("numeric") || r_class.include?("integer") ||
                     r_class.include?("logical") || r_class.include?("character")
                  obj = ::R::Vector.new(r_interop)
                  obj.expression = expression if expression
                  obj
                when r_class.include?("list")
                  ::R::List.new(r_interop, expression)
                when r_class.include?("environment")
                  ::R::Environment.new(r_interop, expression)
                when r_class.include?("function")
                  ::R::Closure.new(r_interop, expression)
                when r_class.include?("language") || r_class == "call"
                  ::R::Language.new(r_interop, expression)
                when r_class == "name" || r_class == "symbol"
                  ::R::RSymbol.new(r_interop, expression)
                when r_class == "expression"
                  ::R::RExpression.new(r_interop, expression)
                else
                  ::Kernel.puts "DEBUG: Object.build fell through to else (r_class=#{r_class.inspect})" if ::ENV['GALAAZ_DEBUG']
                  new(r_interop, expression)
                end
          ::Kernel.puts "DEBUG: Object.build returning #{obj.class}" if ::ENV['GALAAZ_DEBUG']
          return obj
        rescue => e
          ::Kernel.puts "DEBUG: Object.build rescue: #{e.message}" if ::ENV['GALAAZ_DEBUG']
          return new(r_interop, expression)
        end
      else
        # Fallback for already unboxed or unexpected strings
        r_interop
      end
    end

    # Printed representation of the R object (as R would print it).
    def to_s
      return super unless ::R.bridge.ready?
      ::R.bridge.print_r(@r_interop)
    end

    # Phase B: BasicObject has no class; we must define it.
    def class
      ::R::Object
    end

    # true for EXPLICIT_RUBY_SURFACE and for any other symbol (forwarded to R via method_missing).
    def respond_to?(sym, include_private = false)
      sym = sym.to_sym
      return true if EXPLICIT_RUBY_SURFACE.include?(sym)
      true
    end

    # Type check against Ruby modules/classes (e.g. obj.is_a?(R::DataFrame)).
    def is_a?(mod)
      return false unless mod.is_a?(::Module)
      !!(self.class <= mod)
    end
    alias_method :kind_of?, :is_a?

    # Exact class check (e.g. obj.instance_of?(R::Object)).
    def instance_of?(mod)
      return false unless mod.is_a?(::Module)
      self.class == mod
    end

    # Debug string: class, object id, and @r_interop handle.
    def inspect
      "#<#{self.class}:#{__id__.to_s(16)} @r_interop=#{@r_interop.inspect}>"
    end

    alias_method :object_id, :__id__

    # R's class() of this object; unwrapped to a single string when length 1.
    def rclass
      res = ::R::Support.exec_function("class", self)
      val = res.respond_to?(:>>) ? (res >> nil) : res
      val.is_a?(::Array) ? val[0] : val
    end

    # R's typeof() of this object; unwrapped to a single string when length 1.
    def typeof
      res = ::R::Support.exec_function("typeof", self)
      val = res.respond_to?(:>>) ? (res >> nil) : res
      val.is_a?(::Array) ? val[0] : val
    end

    # Unbox this R object to a Ruby value. Recurses until only Ruby values (no R::Object).
    # Plain R::Object: re-evaluates handle; if list (typeof=="list") iterates [[i]] and recurses;
    # if atomic uses [[index+1]] and result protocol (never uses $ on atomic). Raises UnboxDepthError when depth exceeded.
    def unboxed_get(index = nil, depth = 0)
      if depth >= ::R::Support::MAX_UNBOX_DEPTH
        ::Kernel.raise(::R::UnboxDepthError, "unbox: list too deep (max depth #{::R::Support::MAX_UNBOX_DEPTH} exceeded)")
      end
      val = ::R::Support.eval(@r_interop)
      return val unless val.is_a?(::R::Object)
      return val.unboxed_get(index, depth + 1) if val.class.instance_method(:unboxed_get).owner != ::R::Object

      handle = @r_interop.to_s
      safe_handle = handle =~ /\Ag2_v\d+\z/

      # Whole object (index.nil?): plain Object may be a list in R — use typeof/length, never $
      if index.nil?
        type_str = self.typeof.to_s.strip
        len_obj = self.length
        n = len_obj.respond_to?(:unboxed_get) ? len_obj.unboxed_get(0) : len_obj
        n = n.to_i if n.respond_to?(:to_i)
        if type_str == "list" && n.is_a?(::Integer) && n >= 1
          list_handle = handle
          unless safe_handle
            list_handle = ::R::Support.generate_var_name
            ::R.bridge.eval_r("#{list_handle} <- #{::R::Support.parse_arg(self)}")
          end
          arr = []
          (1..n).each do |i|
            elt = ::R::Support.eval("#{list_handle}[[#{i}]]")
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
        # Atomic (or length 0): treat as single element for consistency
        index = 0
      end

      idx = index + 1
      r_code = safe_handle ? "#{handle}[[#{idx}]]" : nil
      unless r_code
        var = ::R::Support.generate_var_name
        ::R.bridge.eval_r("#{var} <- #{::R::Support.parse_arg(self)}")
        r_code = "#{var}[[#{idx}]]"
      end
      val2 = ::R::Support.eval(r_code)
      return val2 unless val2.is_a?(::R::Object)
      return val2.unboxed_get(nil, depth + 1) if val2.class.instance_method(:unboxed_get).owner != ::R::Object

      # Plain R::Object single element: use result protocol until scalar or Vector/List
      r_code = "#{val2.r_interop}[[1]]"
      max_plain = ::R::Support::MAX_UNBOX_DEPTH - depth
      loop do
        var = ::R::Support.generate_var_name
        assignment = "#{var} <- #{r_code}"
        envelope = ::R.bridge.eval_r_with_result(assignment)
        raise "Result protocol: no envelope (buffer missing or invalid)" unless envelope
        case envelope[:type]
        when :scalar_double, :scalar_integer, :scalar_logical, :scalar_symbol
          return envelope[:value]
        when :scalar_character
          v = envelope[:value]
          return (v.is_a?(::String) && v =~ /^rb_obj_\d+$/) ? ::R::Support.get_ruby_object(v) : v
        when :handle
          obj = ::R::Object.build(envelope[:handle], nil, r_class: envelope[:r_class])
          unless obj.instance_of?(::R::Object)
            return obj.unboxed_get(nil, depth + 1)
          end
          r_code = "#{envelope[:handle]}[[1]]"
          max_plain -= 1
          if max_plain <= 0
            ::Kernel.raise(::R::UnboxDepthError, "unbox: list too deep (max depth #{::R::Support::MAX_UNBOX_DEPTH} exceeded)")
          end
        else
          raise "Result protocol: unknown envelope type #{envelope[:type].inspect}"
        end
      end
    end

    # Unbox via >>: same as unboxed_get so (self >> nil) and (self >> 0) work.
    alias_method :>>, :unboxed_get

    # Unboxing semantics (>> nil / to_ruby / unboxed_get(nil)): recurse until result contains only Ruby
    # values (Integer, Float, String, true/false, Array, nil). List → Array (single list → [x]).
    # Atomic length 1 → scalar; length > 1 → Array. Can be expensive for large/deep structures.
    # Raises R::UnboxDepthError when recursion exceeds MAX_UNBOX_DEPTH.

    # Simple way to get a Ruby value: (self >> nil). For length-1 vectors returns the scalar; for longer returns array.
    def to_ruby
      self >> nil
    end

    # Unbox length-1 numeric (or string digits) to Integer without forwarding to R (R has no to_i).
    # Callback procs often use x.to_i when R passes scalars as R::Object.
    def to_i
      v = to_ruby
      v = v.first if v.is_a?(::Array) && v.size == 1
      case v
      when ::Integer then v
      when ::Float then v.to_i
      when ::String then Integer(v)
      else
        Integer(v)
      end
    end

    # Return nil so RSpec/eq and array conversion don't forward to_ary to R (plain Object is not array-like).
    def to_ary
      nil
    end

    # Equality: R::Object vs R::Object uses all.equal; vs Ruby scalar uses unboxed value(s).
    def ==(other)
      return true if self.equal?(other)
      if other.is_a?(::R::Object)
        res = ::R.bridge.eval_r("isTRUE(all.equal(#{@r_interop}, #{other.r_interop}))")
        return res == "[1] TRUE"
      elsif other.is_a?(::Numeric) || other.is_a?(::String) || other.is_a?(::TrueClass) ||
            other.is_a?(::FalseClass) || other.nil? || other.is_a?(::Symbol)
        # DataFrame/Matrix etc. are not equal to a scalar even if they contain that value (e.g. row['mpg'] != 21.0).
        return false if self.class == ::R::DataFrame || self.class == ::R::Matrix
        val = (self >> nil)
        if val.is_a?(::Array)
          return val[0] == other if val.size == 1
          return val.include?(other) if other.is_a?(::String)
        end
        return val == other
      else
        super
      end
    end

    # Call this object as an R function with the given args (e.g. obj.call(1, 2)).
    def call(*args)
      ::R::Support.exec_function(self, *args)
    end

    # Forward unknown methods to R: process_missing(symbol, self, *args) builds and runs the R call.
    def method_missing(symbol, *args)
      ::R::Support.process_missing(symbol, self, *args)
    end
  end
end
