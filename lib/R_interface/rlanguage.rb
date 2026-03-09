# rlanguage.rb
module R
  class Language < Object
    include BinaryOperators
    include LogicalOperators
    include ExpBinOp
    include IndexedObject

    attr_accessor :expression
    
    def self.build(function_name, *args)
      # function_name is something like '`+`' or '`~`'
      op = function_name.delete("`").strip
      
      # We build the string expression by parsing arguments
      lhs = R::Support.parse_arg(args[0])
      rhs = R::Support.parse_arg(args[1])
      if op == ":"
        expr = "#{lhs}#{op}#{rhs}"
      else
        expr = "#{lhs} #{op} #{rhs}"
      end
      
      # Allocate object without calling initialize (which calls bridge)
      res = R::Language.allocate
      res.instance_variable_set(:@r_interop, expr)
      res.expression = expr
      res
    end

    def i
      "I(#{expression})"
    end

    def to_s
      expression || super
    end
  end
end
