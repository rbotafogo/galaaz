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

  # Raised when unboxing recurses beyond MAX_UNBOX_DEPTH (prevents stack/memory exhaustion).
  class UnboxDepthError < RuntimeError; end

  module Support
    @@var_id = 0
    @dispatch_probe_cache = { func: {} }

    # Maximum recursion depth when unboxing lists. Beyond this we raise UnboxDepthError.
    MAX_UNBOX_DEPTH = 100

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
        # Protocol spec: eval returns scalar symbol as Ruby Symbol. R sends symbol/name as handle (type 4); unbox here only.
        r_class = envelope[:r_class].to_s.strip
        if r_class == "name" || r_class == "symbol"
          raw = R.bridge.eval_r("as.character(#{envelope[:handle]})").to_s
          m = raw.match(/\[1\]\s*"([^"]*)"/)
          name = m ? m[1] : raw.strip
          return name.gsub("::", "___").gsub(".", "__").to_sym
        end
        return R::Object.build(envelope[:handle], nil, r_class: envelope[:r_class])
      else
        raise "Result protocol: unknown envelope type #{envelope[:type].inspect}"
      end
    end

    # String suitable for expression display (to_s). For R::Language use stored expression; for other R::Object
    # use R's deparse() so display reflects the current value (not the creating R code stored in .expression).
    def self.expression_display_arg(arg)
      puts "DEBUG expression_display_arg: arg=#{arg.inspect} class=#{arg.class}" if ENV["GALAAZ_DEBUG"]
      return arg.expression if arg.is_a?(R::Language) && arg.respond_to?(:expression) && arg.expression
      return self.get_deparse_string(arg) if arg.is_a?(R::Object)
      self.parse_arg(arg).to_s
    end

    # R-side deparse of an R::Object to a single string (e.g. "c(1L, 2L, 3L, 4L)").
    # Relies on R evaluating deparse() correctly on the object.
    def self.get_deparse_string(arg)
      puts "DEBUG get_deparse_string: called for #{arg.r_interop.inspect}" if ENV["GALAAZ_DEBUG"]
      dep = self.exec_function("deparse", arg)
      puts "DEBUG get_deparse_string: deparse result class=#{dep.class} value=#{dep.inspect}" if ENV["GALAAZ_DEBUG"]
      str = self.exec_function("paste0", dep, { collapse: "" })
      return str.to_s if str.is_a?(::String)
      raw = R.bridge.eval_r("paste0(#{str.r_interop}, collapse='')").to_s
      puts "DEBUG get_deparse_string: eval_r paste0 raw=#{raw.inspect}" if ENV["GALAAZ_DEBUG"]
      m = raw.match(/\[1\]\s*"([^"]*)"/)
      result = m ? m[1] : raw.strip
      puts "DEBUG get_deparse_string: returning #{result.inspect}" if ENV["GALAAZ_DEBUG"]
      result
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
        # :all means "all" in that dimension; R uses missing argument. Bridge defines missing_arg().
        return "missing_arg()" if arg == :all
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
        if R.bridge.respond_to?(:register_callback_proc_stub)
          return R.bridge.register_callback_proc_stub(arg)
        end

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
            if (length(res_str) < 1L) next
            line <- res_str[1]
            if (startsWith(line, '--G_CMD--')) {
              # Extract sequence number if present (regmatches returns list; use [[1]] for sub)
              seq_match <- regmatches(line, regexpr('--G_CMD--seq=([0-9]+)--', line))
              seq_num <- if (length(seq_match) > 0L && length(seq_match[[1]]) > 0L) sub('--G_CMD--seq=([0-9]+)--', '\\\\1', seq_match[[1]]) else '0'
              # Extract actual command
              cmd_part <- sub('--G_CMD--(seq=[0-9]+--)?', '', line)
              cmd <- trimws(cmd_part)
              # Restore newlines (Ruby sends U+E000 as placeholder so FIFO is one line)
              cmd <- gsub(\"#{R::ShadowBridge::TRANSPORT_NL}\", \"\\n\", cmd, fixed=TRUE)
              recv_log <- Sys.getenv('GALAAZ_R_RECEIVED_LOG', '')
              if (nchar(recv_log) > 0L) tryCatch({
                write('---CMD---\\n', file=recv_log, append=TRUE)
                write(cmd, file=recv_log, append=TRUE)
                write('\\n', file=recv_log, append=TRUE)
              }, error=function(e) NULL)
              # Log that we're about to execute a command
              cat('[R_CALLBACK]', 'seq=', seq_num, 'Executing:', substr(cmd, 1, 50), '...\\n', sep='')
              # Wrap entire command handling in tryCatch to ensure --G_CMD_END-- is always sent
              # Use capture.output with explicit print() to ensure output is captured
              tryCatch({
                if (nchar(cmd) > 0L) {
                  # Evaluate in .GlobalEnv so g2_v* handles created by Ruby are visible.
                  # Without this, eval() uses parent.frame() (chunk/engine env) and
                  # object 'g2_vNNN' not found occurs when indexing vectors/matrices.
                  result <- capture.output(print(eval(parse(text=cmd), envir = .GlobalEnv)))
                  cat(result, sep='\\n')
                }
              }, error=function(e) {
                cat('--G_ERR--', conditionMessage(e), '\\n', sep='')
                tb <- paste(capture.output(traceback()), collapse = '\\\\\\\\n')
                if (nchar(tb) > 0L) cat('--G_TRACE--', tb, '\\n', sep='')
              }, finally={
                # Include sequence number in response for synchronization
                cat('--G_CMD_END--seq=', seq_num, '--\\n', sep='')
                flush.console()
              })
            } else if (startsWith(line, '--G_RET--')) {
              res_handle <- trimws(sub('--G_RET--', '', line))
              res_handle <- gsub(\"#{R::ShadowBridge::TRANSPORT_NL}\", \"\\n\", res_handle, fixed=TRUE)
              if (nchar(res_handle) > 0L) return(eval(parse(text=res_handle), envir = .GlobalEnv))
              return(invisible(NULL))
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

    # Run an R call: f_name(args...). Builds assignment, gets envelope from bridge, returns R::Object (boxed).
    # Unbox with .to_ruby, .unboxed_get(0), or >> 0. kwargs (e.g. i:, value:) are merged into args for R named-argument calls like `[[<-`(df, i=..., value=...).
    def self.exec_function(function, *args, unbox: false, **kwargs)
      f_name = function.respond_to?(:r_interop) ? function.r_interop : function

      if args.empty? && kwargs.empty? && (f_name.include?("::") || f_name.start_with?("g2_v"))
        return self.eval(f_name)
      end

      var_name = self.generate_var_name
      all_args = kwargs.empty? ? args : args + [kwargs]
      r_args = all_args.map { |arg| self.parse_arg(arg) }
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
        # Always return R::Object (boxed). Callers unbox with .to_ruby, .unboxed_get(0), or >> 0.
        # Exception: unwrap rb_obj_* handles (stored Ruby objects).
        val = envelope[:value]
        if envelope[:type] == :scalar_character && val.is_a?(String) && val =~ /^rb_obj_\d+$/
          return get_ruby_object(val)
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
      if ENV['GALAAZ_DEBUG_EVAL'] && name == "expr" && args.size >= 1
        puts "[GALAAZ_DEBUG_EVAL] R.expr(...) called:"
        puts "  args[0].class = #{args[0].class}, args[0].inspect = #{args[0].inspect}"
      end
      return process_missing_setter(name, internal, args) if name =~ /(.*)=$/
      return process_missing_eval(name, internal, args) if name == "eval"
      # R.expr(expression_text): build R expression from string/SymbolExprString via parse(text=...), return R::Object.
      if name == "expr" && args.size == 1
        arg = args[0]
        if arg.is_a?(SymbolExprString) || (arg.is_a?(String) && !arg.start_with?("g2_v"))
          str = arg.to_s
          var_name = self.generate_var_name
          R.bridge.eval_r("#{var_name} <- parse(text=#{str.inspect})[[1]]")
          return R::Object.build(var_name)
        end
      end
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
      if internal.is_a?(R::Object) && name == "eval" && args.empty?
        return self.exec_function("eval", internal)
      end
      if internal.is_a?(R::Object) && args.size >= 1
        expr = self.parse_arg(internal)
        env = self.parse_arg(args[0])
        unless expr.start_with?("g2_v") || expr.start_with?("quote(")
          puts "DEBUG: Quoting expression: #{expr}" if ENV['GALAAZ_DEBUG']
          expr = "quote(#{expr})"
        end
        var_name = self.generate_var_name
        r_code = "#{var_name} <- eval(#{expr}, #{env})"
        if ENV['GALAAZ_DEBUG_EVAL']
          puts "[GALAAZ_DEBUG_EVAL] expr.eval(env) path:"
          puts "  internal.class = #{internal.class}"
          puts "  internal.r_interop = #{internal.r_interop.inspect}" if internal.respond_to?(:r_interop)
          puts "  internal.expression = #{internal.expression.inspect}" if internal.respond_to?(:expression)
          puts "  parse_arg(internal) => expr = #{expr.inspect}"
          puts "  parse_arg(args[0]) => env = #{env.inspect}"
          puts "  R code sent: #{r_code}"
        end
        R.bridge.eval_r(r_code)
        return R::Object.build(var_name)
      end
      if args.size == 1
        expr_arg = args[0].is_a?(SymbolExprString) ? args[0].to_s : args[0]
        return self.eval(expr_arg)
      end
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

      # Prefer component/field access (obj.beta => obj[["beta"]]) over calling a global function (beta()).
      # Use [[ instead of $ so we avoid "$ operator is invalid for atomic vectors" when receiver is atomic;
      # [[ on list/data.frame/env returns the element; result protocol maps NA/NULL as appropriate.
      begin
        R.bridge.log_connections_in_r if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true"
        R.bridge.log_object_in_r(handle) if ENV["GALAAZ_DEBUG_R"].to_s == "1" || ENV["GALAAZ_DEBUG_R"].to_s == "true" || ENV["GALAAZ_DEBUG_OBJECT"].to_s == "1" || ENV["GALAAZ_DEBUG_OBJECT"].to_s == "true"
      rescue StandardError => e
        # Debug dump must not block the is_field check (e.g. if R throws "invalid connection" when inspecting the object).
        File.open(R.bridge.log_path("galaaz_obj_debug.log"), "a") { |f| f.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] log_object_in_r(#{handle}) failed: #{e.message}" }
      end
      # In callback, eval_r can fail with "invalid connection" - wrap in begin/rescue
      is_field = begin
        R.bridge.eval_r("isTRUE('#{name}' %in% names(#{handle})) || (is.environment(#{handle}) && isTRUE(exists('#{name}', envir = #{handle}, inherits = FALSE)))") == "[1] TRUE"
      rescue RuntimeError => e
        e.message.include?("invalid connection") ? false : raise
      end
      if is_field
        res = self.exec_function_name("`[[`", internal, name)
        return res.call(*args) if !args.empty? && res.respond_to?(:call)
        return res
      end

      is_func = begin
        cached = @dispatch_probe_cache[:func][name]
        if cached.nil?
          cached = (R.bridge.eval_r("is.function(try(get('#{name}'), silent=TRUE))") == "[1] TRUE")
          @dispatch_probe_cache[:func][name] = cached
        end
        cached
      rescue RuntimeError => e
        e.message.include?("invalid connection") ? false : raise
      end
      return self.exec_function(name, internal, *args) if is_func

      # Environment: missing name should raise NoMethodError (like Ruby), not call name(env) in R.
      if internal.is_a?(::R::Environment)
        ::Kernel.raise(::NoMethodError, "undefined method `#{name}' for #{internal.inspect}")
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
