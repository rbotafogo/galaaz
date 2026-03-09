# ruby_extensions.rb
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
