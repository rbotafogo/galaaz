# ruby_extensions.rb

# Ruby-only expression string builder: :a + :b => "a + b", chaining :a + :b + :c => "a + b + c".
# No R calls; used so R.expr(:e1 + :e2 + :e3) receives a string after Ruby evaluation.
class SymbolExprString
  def initialize(part)
    @str = part.to_s.gsub(/__/, ".")
  end

  def +(other)
    other_str = other.respond_to?(:to_expr_str) ? other.to_expr_str : other.to_s.gsub(/__/, ".")
    SymbolExprString.new("#{@str} + #{other_str}")
  end

  def to_s
    @str
  end
  alias to_expr_str to_s
end

module R
  module ExpBinOp
    def exec_bin_oper(operator, other_object)
      R::Language.build(operator, self, other_object)
    end
    def coerce(numeric)
      [R::Language.new(numeric.to_s), self]
    end
    def inter(other_object)
      exec_bin_oper("`:`", other_object)
    end
    def assign(other_object)
      exec_bin_oper("`<-`", other_object)
    end
  end
end

module R
  class SymbolRef
    include R::BinaryOperators
    include R::ExpBinOp
    include R::LogicalOperators

    REF_RUBY_RESERVED = %i[
      to_str to_path to_ary to_int to_f to_r to_proc to_hash to_h to_a call
    ].freeze

    def initialize(name)
      @name = name
    end

    def to_r_symbol
      @name.to_s.gsub(/__/, ".")
    end

    def +@
      var_name = R::Support.generate_var_name
      R.bridge.eval_r("#{var_name} <- as.name('#{to_r_symbol}')")
      R::Object.build(var_name)
    end

    def ~@
      expr = to_r_symbol
      var_name = R::Support.generate_var_name
      R.bridge.eval_r("#{var_name} <- #{expr}")
      R::Object.build(var_name)
    end

    def up_to(other_object)
      R::Language.build("`:`", self, other_object)
    end

    def method_missing(method_name, *args)
      super if REF_RUBY_RESERVED.include?(method_name)
      name = R::Support.convert_symbol2r(method_name)
      r_args = [self, *args].map { |arg| R::Support.parse_arg(arg) }
      expr = "#{name}(#{r_args.join(", ")})"
      res = R::Language.allocate
      res.instance_variable_set(:@r_interop, expr)
      res.expression = expr
      res
    end

    def respond_to_missing?(method_name, include_private = false)
      return false if method_name == :r_interop || method_name == :expression
      return false if REF_RUBY_RESERVED.include?(method_name)
      true
    end
  end
end

module E
  def self.method_missing(symbol, *args)
    name = R::Support.convert_symbol2r(symbol)
    r_args = args.map { |arg| R::Support.parse_arg(arg) }
    expr = "#{name}(#{r_args.join(", ")})"
    
    res = R::Language.allocate
    res.instance_variable_set(:@r_interop, expr)
    res.expression = expr
    res
  end
end

module Galaaz
  module SymbolDSL
    SYMBOL_RUBY_RESERVED = %i[
      to_str to_path to_ary to_int to_f to_r to_proc to_hash to_h to_a call
    ].freeze

    refine Symbol do
      def __galaaz_ref
        R::SymbolRef.new(self)
      end

      def +(other_object)
        __galaaz_ref + other_object
      end

      def -(other_object)
        __galaaz_ref - other_object
      end

      def *(other_object)
        __galaaz_ref * other_object
      end

      def /(other_object)
        __galaaz_ref / other_object
      end

      def **(other_object)
        __galaaz_ref ** other_object
      end

      def %(other_object)
        __galaaz_ref % other_object
      end

      def int_div(other_object)
        __galaaz_ref.int_div(other_object)
      end

      def eq(other_object)
        __galaaz_ref.eq(other_object)
      end

      def eql(other_object)
        __galaaz_ref.eql(other_object)
      end

      def <(other_object)
        __galaaz_ref < other_object
      end

      def <=(other_object)
        __galaaz_ref <= other_object
      end

      def >(other_object)
        __galaaz_ref > other_object
      end

      def >=(other_object)
        __galaaz_ref >= other_object
      end

      def !=(other_object)
        __galaaz_ref != other_object
      end

      def ne(other_object)
        __galaaz_ref.ne(other_object)
      end

      def til(other_object)
        __galaaz_ref.til(other_object)
      end

      def inter(other_object)
        __galaaz_ref.inter(other_object)
      end

      def assign(other_object)
        __galaaz_ref.assign(other_object)
      end

      def _(op, other_object)
        __galaaz_ref._(op, other_object)
      end

      def &(other_object)
        __galaaz_ref.&(other_object)
      end

      def |(other_object)
        __galaaz_ref.|(other_object)
      end

      def +@
        __galaaz_ref.+@
      end

      def ~@
        __galaaz_ref.~@
      end

      def up_to(other_object)
        __galaaz_ref.up_to(other_object)
      end

      def method_missing(method_name, *args)
        return super if Galaaz::SymbolDSL::SYMBOL_RUBY_RESERVED.include?(method_name)
        __galaaz_ref.public_send(method_name, *args)
      end

      def respond_to_missing?(method_name, include_private = false)
        return false if Galaaz::SymbolDSL::SYMBOL_RUBY_RESERVED.include?(method_name)
        __galaaz_ref.respond_to?(method_name, include_private) || super
      end
    end
  end
end

#--------------------------------------------------------------------------------------
# NilClass: R NULL is converted to Ruby nil. So nil must respond to is__null / isTRUE
# so that code like obj.is__null.unboxed_get(0) does not raise when obj is nil.
#--------------------------------------------------------------------------------------
module R
  # Result object for nil.is__null so that nil.is__null.unboxed_get(0) => true.
  class NullCheckResult
    def initialize(bool)
      @bool = bool
    end
    def unboxed_get(_index = nil)
      @bool
    end
    # For (nil.is__null | x).unboxed_get(0): true | x => true; false | x => x
    def |(other)
      @bool ? self : other
    end
  end
  NULL_IS_NULL = NullCheckResult.new(true).freeze
  NULL_IS_FALSE = NullCheckResult.new(false).freeze
end

class NilClass
  # R NULL becomes Ruby nil; treat nil as null so .is__null.unboxed_get(0) works.
  def is__null
    R::NULL_IS_NULL
  end
  # R's isTRUE(NULL) is FALSE; so nil.isTRUE.unboxed_get(0) => false.
  def isTRUE
    R::NULL_IS_FALSE
  end
end
