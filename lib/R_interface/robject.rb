# robject.rb
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
      :==, :equal?, :call,
      :is_a?, :kind_of?, :instance_of?, :respond_to?,
      :method_missing
    ].freeze

    attr_reader :r_interop
    attr_accessor :expression

    def initialize(r_interop, expression = nil)
      @r_interop = r_interop
      @expression = expression
    end

    def self.build(r_interop, expression = nil, r_class: nil)
      # Check for Ruby object handles first
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

    def to_s
      return super unless ::R.bridge.ready?
      ::R.bridge.print_r(@r_interop)
    end

    # Phase B: BasicObject has no class; we must define it.
    def class
      ::R::Object
    end

    def respond_to?(sym, include_private = false)
      sym = sym.to_sym
      return true if EXPLICIT_RUBY_SURFACE.include?(sym)
      # Any other symbol may be forwarded to R via method_missing
      true
    end

    def is_a?(mod)
      return false unless mod.is_a?(::Module)
      !!(self.class <= mod)
    end
    alias_method :kind_of?, :is_a?

    def instance_of?(mod)
      return false unless mod.is_a?(::Module)
      self.class == mod
    end

    def inspect
      "#<#{self.class}:#{__id__.to_s(16)} @r_interop=#{@r_interop.inspect}>"
    end

    alias_method :object_id, :__id__

    def rclass
      res = ::R::Support.exec_function("class", self)
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    def typeof
      res = ::R::Support.exec_function("typeof", self)
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

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

    def call(*args)
      ::R::Support.exec_function(self, *args)
    end

    def method_missing(symbol, *args)
      ::R::Support.process_missing(symbol, self, *args)
    end
  end
end
