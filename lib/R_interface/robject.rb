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
      :[], :[]=, :>>, :unboxed_get, :length, :size,
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
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    # R's typeof() of this object; unwrapped to a single string when length 1.
    def typeof
      res = ::R::Support.exec_function("typeof", self)
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    # Unbox this R object to a Ruby value. Used when the receiver is a plain R::Object
    # (e.g. from a callback or list element that wasn't built as Vector/List). Re-evaluates
    # the handle so we get the proper wrapper (scalar or Vector/List); delegates to that
    # type's unboxed_get when possible; otherwise indexes in R with [[index+1]] for a scalar.
    def unboxed_get(index = nil)
      val = ::R::Support.eval(@r_interop)
      return val unless val.is_a?(::R::Object)
      return val.unboxed_get(index) unless val.instance_of?(::R::Object)
      # Plain R::Object: get element via R [[index+1]] (R is 1-based). Only interpolate
      # handle if it looks like a safe var name (g2_vN) to avoid injecting backslashes etc.
      idx = index.nil? ? 1 : index + 1
      handle = @r_interop.to_s
      if handle =~ /\Ag2_v\d+\z/
        r_code = "#{handle}[[#{idx}]]"
      else
        var = ::R::Support.generate_var_name
        ::R.bridge.eval_r("#{var} <- #{::R::Support.parse_arg(self)}")
        r_code = "#{var}[[#{idx}]]"
      end
      val2 = ::R::Support.eval(r_code)
      return val2 unless val2.is_a?(::R::Object)
      return val2.respond_to?(:unboxed_get) ? val2.unboxed_get(0) : val2
    end

    # Unbox via >>: same as unboxed_get so (self >> nil) and (self >> 0) work.
    alias_method :>>, :unboxed_get

    # Equality: R::Object vs R::Object uses all.equal; vs Ruby scalar uses unboxed value(s).
    def ==(other)
      return true if self.equal?(other)
      if other.is_a?(::R::Object)
        res = ::R.bridge.eval_r("isTRUE(all.equal(#{@r_interop}, #{other.r_interop}))")
        return res == "[1] TRUE"
      elsif other.is_a?(::Numeric) || other.is_a?(::String) || other.is_a?(::TrueClass) ||
            other.is_a?(::FalseClass) || other.nil? || other.is_a?(::Symbol)
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
