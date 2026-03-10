# rsupport.rb
#
# R::Support provides the core translation layer between Ruby and R: symbol conversion,
# argument parsing (parse_arg), evaluation (eval), and dispatching (exec_function,
# process_missing). process_missing is the entry point when an R::Object or the R
# module receives an unknown method: it handles setters (x=), eval, and generic
# calls (function, field access, or method with receiver as first arg).
#
require 'singleton'

module R
  def self.empty_symbol
    ""
  end

  # Singleton representing R's NA; used when R returns NA and we keep it as a sentinel in Ruby.
  class NotAvailable
    def to_s; "NA"; end
    def r_interop; "NA"; end
  end
  NA = NotAvailable.new

  module Support
    @@var_id = 0

    # Generate a unique R-side variable name (e.g. g2_v1, g2_v2) for assignment results.
    def self.generate_var_name
      @@var_id += 1
      "g2_v#{@@var_id}"
    end

    # Convert a Ruby method name to the R name: __ => ., ___ => ::, rclass => class, eql => ==.
    def self.convert_symbol2r(symbol)
      name = symbol.to_s
      name.gsub!(/___/, "::")
      name.gsub!(/__/, ".")
      case name
      when "rclass" then "class"
      when "eql"    then "=="
      else name
      end
    end

    # Evaluate an R expression (string, Language, or handle). Returns a scalar value or R::Object.build(...).
    # Uses .expression or .r_interop when present so we never treat R's printed output as code.
    def self.eval(string)
      puts "DEBUG: Support.eval(#{string.inspect})" if ENV['GALAAZ_DEBUG']

      var_name = self.generate_var_name
      r_code = if string.respond_to?(:expression) && string.expression
                 string.expression.to_s
               elsif string.respond_to?(:r_interop) && string.r_interop.is_a?(::String) && string.r_interop.start_with?("g2_v")
                 string.r_interop
               else
                 string.to_s
               end
      
      # Determine if we need to wrap in braces or use eval()
      # If it's a handle, we MUST use eval() in R to get its value if it's a symbol
      final_r_code = if r_code.start_with?("g2_v")
                       "eval(#{r_code})"
                     elsif r_code.include?("\n") && !r_code.strip.start_with?("{") && !r_code.include?("<-") && !r_code.include?("=")
                       "{#{r_code}\n}"
                     else
                       r_code
                     end

      assignment = ".GlobalEnv$#{var_name} <- { #{final_r_code}\n }"
      envelope = R.bridge.eval_r_with_result(assignment)
      if ENV['GALAAZ_DEBUG']
        puts "DEBUG: eval envelope=#{envelope.inspect}"
      end
      raise "Result protocol: no envelope (buffer missing or invalid)" unless envelope

      case envelope[:type]
      when :scalar_double, :scalar_integer, :scalar_logical
        return envelope[:value]
      when :scalar_character
        return R::Object.build(var_name, nil, r_class: "character")
      when :scalar_symbol
        return envelope[:value]
      when :handle
        return R::Object.build(envelope[:handle], nil, r_class: envelope[:r_class])
      else
        raise "Result protocol: unknown envelope type #{envelope[:type].inspect}"
      end
    end

    # Turn a Ruby value into an R code fragment (string): handles, scalars, hashes -> list(), arrays -> c(), Procs -> R callback stub, etc.
    def self.parse_arg(arg)
      return arg.r_interop if arg.respond_to?(:r_interop) && arg.r_interop
      return arg.expression if arg.respond_to?(:expression) && arg.expression

      case arg
      when Hash
        arg.map do |k, v|
          key = k.to_s.gsub(/__/, ".")
          # R list names with spaces or special chars must be backtick-quoted
          key_r = (key =~ /\A[a-zA-Z._][a-zA-Z0-9._]*\z/) ? key : "`#{key.gsub('`', '\\`')}`"
          "#{key_r} = #{self.parse_arg(v)}"
        end.join(", ")
      when Array
        "c(#{arg.map { |v| self.parse_arg(v) }.join(", ")})"
      when Symbol
        # Native Ruby symbols map to R names. :all is a special case for empty index.
        return "" if arg == :all
        arg.to_s.gsub(/__/,".")
      when String
        # If it's already a handle, don't quote it
        if arg.start_with?("g2_v")
          arg
        else
          "'#{arg.gsub("'", "\\\\'")}'"
        end
      when Numeric
        arg.to_s + (arg.is_a?(Integer) ? "L" : "")
      when TrueClass
        "TRUE"
      when FalseClass
        "FALSE"
      when Range
        final_value = (arg.exclude_end?) ? (arg.last - 1) : arg.last
        "seq(#{arg.first}, #{final_value})"
      when Proc, Method
        id = R::Support.register_callback(arg)
        "function(...) {
          args <- list(...)
          handles <- character(0)
          if (length(args) > 0) {
            for (i in 1:length(args)) {
              h <- paste0('g2_v_cb_', i, '_', as.integer(runif(1, 1e8, 9e8)))
              assign(h, args[[i]], envir = .GlobalEnv)
              cls <- paste(class(args[[i]]), collapse=' ')
              handles <- c(handles, paste0(h, ':', cls))
            }
          }
          cat('--G_CALLBACK--#{id}--', paste(handles, collapse='|'), '--\\n', sep='')
          flush.console()
          while(TRUE) {
            res_str <- readLines('/dev/shm/galaaz_callback_fifo', n=1)
            if (startsWith(res_str, '--G_CMD--')) {
              cmd <- sub('--G_CMD--', '', res_str)
              cat(capture2(eval(parse(text=cmd))), sep='\\n')
              cat('--G_CMD_END--\\n')
              flush.console()
            } else if (startsWith(res_str, '--G_RET--')) {
              res_handle <- sub('--G_RET--', '', res_str)
              return(eval(parse(text=res_handle)))
            }
          }
        }"
      when nil
        "NULL"
      else
        handle = self.register_ruby_object(arg)
        "'#{handle}'"
      end
    end

    # Run an R call: f_name(args...). Builds assignment, gets envelope from bridge, then unboxes or builds R::Object per envelope type and f_name.
    def self.exec_function(function, *args)
      f_name = function.respond_to?(:r_interop) ? function.r_interop : function

      if args.empty? && (f_name.include?("::") || f_name.start_with?("g2_v"))
        return self.eval(f_name)
      end

      var_name = self.generate_var_name
      r_args = args.map { |arg| self.parse_arg(arg) }
      # eval(expr, envir): R expects expr as expression; parse_arg on Language returns bare string -> wrap in parse(text=...) so envir is used
      if f_name == "eval" && args.size == 2 && !r_args[0].to_s.start_with?("g2_v", "quote(")
        r_args[0] = "parse(text=#{r_args[0].to_s.inspect})"
      end

      r_expr = "#{f_name}(#{r_args.join(", ")})"
      assignment = "#{var_name} <- #{r_expr}"
      envelope = R.bridge.eval_r_with_result(assignment)
      unless envelope
        reason = R.bridge.respond_to?(:last_envelope_nil_reason) && R.bridge.last_envelope_nil_reason
        raise "Result protocol: no envelope (buffer missing or invalid)#{reason ? " [#{reason}]" : ''}"
      end

      case envelope[:type]
      when :scalar_double, :scalar_integer, :scalar_logical, :scalar_character
        # Return raw scalar for pure scalars; box c, hyp, length for R objects.
        # Never unbox numeric/logical for `[` or `[[` so single-cell extractions stay R::Object and .all__equal works.
        # Exception: always unwrap rb_obj_* handles (stored Ruby objects) even from `[[`.
        val = envelope[:value]
        if envelope[:type] == :scalar_character && val.is_a?(String) && val =~ /^rb_obj_\d+$/
          return get_ruby_object(val)
        end
        unbox = f_name != "c" && f_name != "hyp" && f_name != "length" && f_name != "`[`" && f_name != "`[[`"
        if unbox
          return val
        end
        r_class = { scalar_double: "numeric", scalar_integer: "integer", scalar_logical: "logical", scalar_character: "character" }[envelope[:type]]
        return R::Object.build(var_name, r_expr, r_class: r_class)
      when :scalar_symbol
        return envelope[:value]
      when :handle
        # Never unbox single-cell for `[`; keep as R::Object so .all__equal and other R methods work.
        return R::Object.build(envelope[:handle], r_expr, r_class: envelope[:r_class])
      else
        raise "Result protocol: unknown envelope type #{envelope[:type].inspect}"
      end
    end

    class << self
      alias_method :exec_function_name, :exec_function
    end

    # Entry point for method_missing: handle setters (x=), eval, or dispatch to R (function / field / method with receiver).
    def self.process_missing(symbol, internal, *args)
      name = self.convert_symbol2r(symbol)
      return process_missing_setter(name, internal, args) if name =~ /(.*)=$/
      return process_missing_eval(name, internal, args) if name == "eval"
      process_missing_dispatch(name, internal, args)
    end

    # Handle obj.var = rhs or R.var = rhs: use `var<-` or `$<-` on R::Object, else .GlobalEnv assignment.
    def self.process_missing_setter(name, internal, args)
      var = name[/^(.*)=$/, 1]
      rhs = self.parse_arg(args[0])
      if internal.is_a?(R::Object)
        handle = internal.r_interop
        r_var = (var == "rclass") ? "class" : var
        R.bridge.eval_r(<<~RCODE)
          #{handle} <- tryCatch(
            `#{r_var}<-`(#{handle}, #{rhs}),
            error = function(e) `$<-`(#{handle}, '#{var}', #{rhs})
          )
        RCODE
      else
        R.bridge.eval_r(".GlobalEnv$#{var} <- #{rhs}")
      end
    end

    # Handle obj.eval(env) or R.eval(code): expression in context, or single-arg R.eval.
    def self.process_missing_eval(name, internal, args)
      if internal.is_a?(R::Object) && args.size >= 1
        expr = self.parse_arg(internal)
        env = self.parse_arg(args[0])
        unless expr.start_with?("g2_v") || expr.start_with?("quote(")
          puts "DEBUG: Quoting expression: #{expr}" if ENV['GALAAZ_DEBUG']
          expr = "quote(#{expr})"
        end
        var_name = self.generate_var_name
        R.bridge.eval_r("#{var_name} <- eval(#{expr}, #{env})")
        return R::Object.build(var_name)
      end
      return self.eval(args[0]) if args.size == 1
      self.exec_function(name, *args)
    end

    # Dispatch: R module (eval handle/namespace or exec_function) or R::Object (length / function / field / fallback).
    def self.process_missing_dispatch(name, internal, args)
      if internal == R && args.empty? && (name.include?("::") || name.start_with?("g2_v"))
        return R::Object.build(name)
      end

      unless internal.is_a?(R::Object)
        return self.exec_function(name, *args)
      end

      handle = internal.r_interop
      return self.exec_function("length", internal, *args) if name == "length"

      is_func = R.bridge.eval_r("is.function(try(get('#{name}'), silent=TRUE))") == "[1] TRUE"
      return self.exec_function(name, internal, *args) if is_func

      is_field = R.bridge.eval_r("isTRUE('#{name}' %in% names(#{handle})) || (is.environment(#{handle}) && isTRUE(exists('#{name}', envir = #{handle}, inherits = FALSE)))") == "[1] TRUE"
      if is_field
        res = self.exec_function_name("`$`", internal, name)
        return res.call(*args) if !args.empty? && res.respond_to?(:call)
        return res
      end

      self.exec_function(name, internal, *args)
    end


    @callbacks = {}
    @ruby_objects = {}
    @ruby_obj_id = 0
    @ruby_object_id = 0

    # Store a Ruby object for passing to R; returns handle string "rb_obj_<id>" for use in R.
    def self.register_ruby_object(obj)
      @ruby_object_id += 1
      id = @ruby_object_id
      @ruby_objects[id] = obj
      "rb_obj_#{id}"
    end

    # Register a Proc/Method to be invoked from R (e.g. in outer()); returns callback id for the R stub.
    def self.register_callback(proc)
      @ruby_obj_id += 1
      id = @ruby_obj_id
      @callbacks[id] = proc
      id
    end

    # Retrieve the Ruby proc registered for a callback id (from --G_CALLBACK--id--...).
    def self.get_callback(id)
      @callbacks[id.to_i]
    end

    # Retrieve the Ruby object for a handle "rb_obj_<id>" returned from R.
    def self.get_ruby_object(id_str)
      id = id_str.sub("rb_obj_", "").to_i
      @ruby_objects[id]
    end
  end
end

require_relative 'r_module_s'
require_relative 'rsupport_scope'
