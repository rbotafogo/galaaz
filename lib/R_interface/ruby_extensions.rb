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

class Symbol
  include R::BinaryOperators
  include R::ExpBinOp
  include R::LogicalOperators

  def +@
    var_name = R::Support.generate_var_name
    R.bridge.eval_r("#{var_name} <- as.name('#{self.to_s.gsub(/__/,".")}')")
    R::Object.build(var_name)
  end

  def ~@
    expr = self.to_s.gsub(/__/,".")
    var_name = R::Support.generate_var_name
    R.bridge.eval_r("#{var_name} <- #{expr}")
    R::Object.build(var_name)
  end

  def succ
    self.to_s.succ.to_sym
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
