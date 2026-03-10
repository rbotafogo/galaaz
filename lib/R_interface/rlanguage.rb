# rlanguage.rb
module R
  class Language < Object
    include BinaryOperators
    include LogicalOperators
    include ExpBinOp
    include IndexedObject

    def class
      ::R::Language
    end

    attr_accessor :expression
    
    def self.build(function_name, *args)
      # function_name is something like '`+`' or '`~`'
      op = function_name.delete("`").strip
      lhs = ::R::Support.parse_arg(args[0])
      rhs = ::R::Support.parse_arg(args[1])
      r_expr = (op == ":") ? "#{lhs}#{op}#{rhs}" : "#{lhs} #{op} #{rhs}"
      lhs_display = ::R::Support.expression_display_arg(args[0])
      rhs_display = ::R::Support.expression_display_arg(args[1])
      expr_display = (op == ":") ? "#{lhs_display}#{op}#{rhs_display}" : "#{lhs_display} #{op} #{rhs_display}"
      res = ::R::Language.allocate
      res.instance_variable_set(:@r_interop, r_expr)
      res.expression = expr_display
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
