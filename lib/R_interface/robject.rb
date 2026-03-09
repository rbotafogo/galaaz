# robject.rb
require_relative 'r_methods'

module R
  class Object
    include IndexedObject
    include BinaryOperators
    include ExecBinOp
    include UnaryOperators
    include ExecUniOp
    
    attr_reader :r_interop
    attr_accessor :expression

    def initialize(r_interop, expression = nil)
      @r_interop = r_interop
      @expression = expression
    end

    def self.build(r_interop, expression = nil, r_class: nil)
      # Check for Ruby object handles first
      if r_interop.is_a?(String) && r_interop.start_with?("rb_obj_")
        return R::Support.get_ruby_object(r_interop)
      end

      # If we got a basic Ruby type, it's already unboxed
      return r_interop if r_interop.is_a?(Numeric) || r_interop.is_a?(TrueClass) ||
                         r_interop.is_a?(FalseClass) || r_interop.nil? || r_interop.is_a?(Symbol)

      if r_interop.is_a?(String) && r_interop.start_with?("g2_v")
        return new(r_interop, expression) unless R.bridge.ready?

        begin
          r_class_arg = r_class
          r_class = r_class.to_s.strip
          r_class = nil if r_class.nil? || r_class.empty?
          r_class ||= R.bridge.eval_r("paste(class(#{r_interop}), collapse=' ')").gsub(/^\[1\] /, "").gsub(/"/, "").strip
          if ENV['GALAAZ_DEBUG']
            puts "DEBUG: Object.build r_interop=#{r_interop.inspect} r_class_arg=#{r_class_arg.inspect} r_class=#{r_class.inspect}"
          end
          obj = case
                when r_class.include?("data.frame") || r_class.include?("tbl_df")
                  R::DataFrame.new(r_interop, expression)
                when r_class.include?("matrix") || r_class.include?("array")
                  R::Matrix.new(r_interop, expression)
                when r_class.include?("numeric") || r_class.include?("integer") ||
                     r_class.include?("logical") || r_class.include?("character")
                  obj = R::Vector.new(r_interop)
                  obj.expression = expression if expression
                  obj
                when r_class.include?("list")
                  R::List.new(r_interop, expression)
                when r_class.include?("function")
                  R::Closure.new(r_interop, expression)
                when r_class == "name" || r_class == "symbol"
                  R::RSymbol.new(r_interop, expression)
                when r_class == "expression"
                  R::RExpression.new(r_interop, expression)
                else
                  puts "DEBUG: Object.build fell through to else (r_class=#{r_class.inspect})" if ENV['GALAAZ_DEBUG']
                  new(r_interop, expression)
                end
          puts "DEBUG: Object.build returning #{obj.class}" if ENV['GALAAZ_DEBUG']
          return obj
        rescue => e
          puts "DEBUG: Object.build rescue: #{e.message}" if ENV['GALAAZ_DEBUG']
          return new(r_interop, expression)
        end
      else
        # Fallback for already unboxed or unexpected strings
        r_interop
      end
    end

    def to_s
      return super unless R.bridge.ready?
      R.bridge.print_r(@r_interop)
    end

    def rclass
      res = R::Support.exec_function("class", self)
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    def typeof
      res = R::Support.exec_function("typeof", self)
      res.respond_to?(:>>) ? (res >> nil)[0] : res
    end

    def ==(other)
      return true if self.equal?(other)
      if other.is_a?(R::Object)
        res = R.bridge.eval_r("isTRUE(all.equal(#{@r_interop}, #{other.r_interop}))")
        return res == "[1] TRUE"
      elsif other.is_a?(Numeric) || other.is_a?(String) || other.is_a?(TrueClass) || 
            other.is_a?(FalseClass) || other.nil? || other.is_a?(Symbol)
        val = (self >> nil)
        if val.is_a?(Array)
          return val[0] == other if val.size == 1
          return val.include?(other) if other.is_a?(String)
        end
        return val == other
      else
        super
      end
    end

    def call(*args)
      R::Support.exec_function(self, *args)
    end

    def method_missing(symbol, *args)
      R::Support.process_missing(symbol, self, *args)
    end
  end
end
