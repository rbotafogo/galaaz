# frozen_string_literal: true

require 'singleton'
require_relative '../new_bridge'

module R
  # Phase 5.1 adapter: expose a minimal compatibility surface for legacy call sites
  # that historically depended on ShadowBridge (now deprecated/obsolete).
  # backed by NewBridge::SessionClient.
  #
  # Implemented compatibility methods:
  # - eval_r(code)
  # - eval_r_with_result("g2_v_x <- ...")
  # - ready?
  # - in_callback?
  # - close
  class NewBridgeAdapter
    include Singleton

    def initialize
      @in_callback = false
      @ready = false
      source_path = ENV['GALAAZ_NEW_BRIDGE_SOURCE'] ||
                    File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)
      @client = NewBridge::SessionClient.new(source_path: source_path)
      @client.start(accept_timeout: 120)
      bootstrap_session!
      @ready = true
    end

    # After a hung/timed-out R eval (e.g. install.packages), kill R and start a fresh runtime
    # so the compile does not keep running and OOM the host shell.
    def restart_runtime!(accept_timeout: 120)
      @ready = false
      @client.restart!(accept_timeout: accept_timeout)
      bootstrap_session!
      @ready = true
      self
    end

    def bootstrap_session!
      # Compatibility with the legacy ShadowBridge setup:
      # - `R.awt` / X11 for plotting (examples/sthda_ggplot).
      # - `missing_arg()` for Ruby :all in `[` / tbl subset (R::Support.parse_arg).
      #   Use rlang::missing_arg when available: tibble/tidyselect reject the legacy
      #   quote(f(,0))[[2]] sentinel ("Subscript ... can't contain the empty string").
      # The gatekeeper evaluates each REQ in a dedicated per-session env; globals are shared.
      init_timeout = effective_bridge_timeout(timeout: nil)
      @client.eval_r(
        <<~RCODE,
          ({
            assign('awt', function(...) { X11(...) }, envir = .GlobalEnv)
            if (requireNamespace('rlang', quietly = TRUE)) {
              assign('missing_arg', getExportedValue('rlang', 'missing_arg'), envir = .GlobalEnv)
            } else {
              assign('missing_arg', function() { quote(f(,0))[[2]] }, envir = .GlobalEnv)
            }
            # Build tidyselect-compatible range expressions from symbols, e.g. year:day.
            if (!exists('range_helper', envir = .GlobalEnv, inherits = FALSE)) {
              assign('range_helper', function(col_ini, col_end, remove = FALSE) {
                ini <- substitute(col_ini)
                fin <- substitute(col_end)
                rng <- as.call(list(as.name(':'), ini, fin))
                if (isTRUE(remove)) {
                  as.call(list(as.name('-'), rng))
                } else {
                  rng
                }
              }, envir = .GlobalEnv)
            }
            if (!exists('up_to', envir = .GlobalEnv, inherits = FALSE)) {
              assign('up_to', function(col_ini, col_end, remove = FALSE) {
                range_helper(col_ini, col_end, remove = remove)
              }, envir = .GlobalEnv)
            }
            # Legacy Galaaz: env_names(env) lists bindings (base R has no env_names).
            if (!exists('env_names', envir = .GlobalEnv, inherits = FALSE)) {
              assign('env_names', function(envir) {
                if (missing(envir)) envir <- parent.frame()
                ls(envir = envir, all.names = TRUE, sorted = TRUE)
              }, envir = .GlobalEnv)
            }
            # Session-scoped environment helpers for transient bridge state.
            if (!exists('galaaz_ensure_session_env', envir = .GlobalEnv, inherits = FALSE)) {
              assign('galaaz_ensure_session_env', function(session_id) {
                sid <- as.character(session_id)
                # Primary path: reuse gatekeeper's per-session registry.
                if (exists('.galaaz_sessions', envir = .GlobalEnv, inherits = FALSE)) {
                  sessions <- get('.galaaz_sessions', envir = .GlobalEnv, inherits = FALSE)
                  if (!is.list(sessions)) {
                    sessions <- list()
                  }
                  if (is.null(sessions[[sid]])) {
                    sessions[[sid]] <- new.env(parent = .GlobalEnv)
                    assign('.galaaz_sessions', sessions, envir = .GlobalEnv)
                  }
                  return(sessions[[sid]])
                }
                # Compatibility fallback if gatekeeper registry is unavailable.
                nm <- paste0('galaaz_session_env_', gsub('[^A-Za-z0-9_]', '_', sid))
                if (!exists(nm, envir = .GlobalEnv, inherits = FALSE)) {
                  assign(nm, new.env(parent = .GlobalEnv), envir = .GlobalEnv)
                }
                get(nm, envir = .GlobalEnv, inherits = FALSE)
              }, envir = .GlobalEnv)
            }
            if (!exists('galaaz_assign_session', envir = .GlobalEnv, inherits = FALSE)) {
              assign('galaaz_assign_session', function(session_id, key, value) {
                en <- galaaz_ensure_session_env(session_id)
                assign(as.character(key), value, envir = en)
                invisible(NULL)
              }, envir = .GlobalEnv)
            }
            if (!exists('galaaz_get_session', envir = .GlobalEnv, inherits = FALSE)) {
              assign('galaaz_get_session', function(session_id, key) {
                en <- galaaz_ensure_session_env(session_id)
                get(as.character(key), envir = en, inherits = FALSE)
              }, envir = .GlobalEnv)
            }
            if (!exists('galaaz_rm_session', envir = .GlobalEnv, inherits = FALSE)) {
              assign('galaaz_rm_session', function(session_id, key) {
                en <- galaaz_ensure_session_env(session_id)
                rm(list = as.character(key), envir = en, inherits = FALSE)
                invisible(NULL)
              }, envir = .GlobalEnv)
            }
            0L
          })
        RCODE
        session_id: current_session_id,
        parent_id: callback_parent_id,
        timeout: init_timeout
      )
    end

    def ready?
      @ready
    end

    def in_callback?
      @in_callback
    end

    # Execute bridge operations within a specific NewBridge session_id.
    # Scope is thread-local and restored after block execution.
    def with_session(session_id)
      old = Thread.current[:galaaz_new_bridge_session_id]
      Thread.current[:galaaz_new_bridge_session_id] = session_id.to_s
      yield
    ensure
      Thread.current[:galaaz_new_bridge_session_id] = old
    end

    # Minimal textual compatibility for existing call sites that expect
    # "[1] <value>" style output for simple scalar evaluations.
    def eval_r(code, timeout: nil)
      effective_timeout = effective_bridge_timeout(timeout: timeout)
      if ENV['GALAAZ_TIMEOUT_DEBUG']
        STDERR.puts "[TIMEOUT_DEBUG] NewBridgeAdapter.eval_r timeout=#{effective_timeout}s explicit_timeout=#{timeout.inspect} env_bridge=#{ENV['GALAAZ_BRIDGE_TIMEOUT_SEC'].inspect}"
        STDERR.flush
      end
      out = @client.eval_r(code, session_id: current_session_id, parent_id: callback_parent_id, timeout: effective_timeout)
      format_scalar_print(out)
    rescue NewBridge::SessionClient::RProcessError => e
      # Compatibility fallback for side-effect-only evals:
      # only retry when the error clearly matches phase1 scalar restrictions.
      raise unless phase1_scalar_fallback_error?(e)

      @client.eval_r("({ #{code}; 0L })", session_id: current_session_id, parent_id: callback_parent_id, timeout: effective_timeout)
      ''
    end

    # Async string eval: +block+ receives +NewBridge::EvalResult+; on success +#value+ is the same
    # formatted string as +eval_r+ (no phase1 scalar fallback retry on async path).
    #
    # @param timeout [nil, Numeric] +nil+ means wait without Ruby-side limit; numeric starts a timer.
    def eval_r_async(code, timeout: nil, &block)
      raise ArgumentError, 'eval_r_async requires a block' unless block

      @client.eval_r_async(code.to_s,
                           session_id: current_session_id,
                           parent_id: callback_parent_id,
                           timeout: timeout) do |raw|
        mapped =
          if raw.ok?
            begin
              NewBridge::EvalResult.success(format_scalar_print(raw.value))
            rescue StandardError => e
              NewBridge::EvalResult.failure(e)
            end
          else
            raw
          end
        block.call(mapped)
      end
    end

    # Async +eval_r_with_result+ payload; +block+ receives +NewBridge::EvalResult+ where success +#value+
    # is a Hash +:envelope+, +:var_name+, +:r_expr+ for +R::Support.ruby_result_from_envelope+.
    def eval_r_with_result_async(assignment_code, timeout: nil, &block)
      raise ArgumentError, 'eval_r_with_result_async requires a block' unless block

      code = "__G_EVAL_WITH_RESULT__#{assignment_code}"
      @client.eval_r_async(code,
                           session_id: current_session_id,
                           parent_id: callback_parent_id,
                           timeout: timeout) do |raw|
        if raw.ok?
          begin
            env = to_legacy_envelope(raw.value)
            m = assignment_code.match(/\A(\S+)\s*<-\s*(.*)\z/m)
            unless m
              block.call(NewBridge::EvalResult.failure(StandardError.new("eval_r_with_result_async: bad assignment #{assignment_code.inspect}")))
              next
            end
            vn = m[1]
            rx = m[2].to_s.strip
            block.call(NewBridge::EvalResult.success(envelope: env, var_name: vn, r_expr: rx))
          rescue StandardError => e
            block.call(NewBridge::EvalResult.failure(e))
          end
        else
          block.call(raw)
        end
      end
    end

    # Return the printed representation of an R object as a Ruby string.
    def print_r(var_name)
      parsed = @client.eval_r("paste(capture.output(print(#{var_name})), collapse='\\n')",
                              session_id: current_session_id,
                              parent_id: callback_parent_id,
                              timeout: effective_bridge_timeout(timeout: nil))
      if parsed['kind'].to_s == 'character'
        unescape_scalar_character(parsed['value'].to_s)
      else
        parsed['value'].to_s
      end
    end

    # Legacy-compatible envelope shape expected by existing bridge specs.
    # Supports scalar assignments used by current migration subset.
    def eval_r_with_result(assignment_code)
      parsed = @client.eval_r("__G_EVAL_WITH_RESULT__#{assignment_code}",
                              session_id: current_session_id,
                              parent_id: callback_parent_id,
                              timeout: effective_bridge_timeout(timeout: nil))
      to_legacy_envelope(parsed)
    end

    # Multiple eval_r_with_result-style assignments in one REQ/RET (Phase 4). Fail-fast: first R error
    # skips remaining ops. Transport still returns HTTP-like success with payload kind +batch_error+.
    # @return [Array<Hash>] legacy envelopes in order
    # @raise [R::BatchEvaluationError] on first failed op (+#failed_index+ is 0-based)
    def batch_eval_r_with_result(assignment_codes)
      codes = Array(assignment_codes).map(&:to_s)
      raise ArgumentError, 'batch_eval_r_with_result requires at least one assignment' if codes.empty?

      body = codes.join("\u001E")
      parsed = @client.eval_r("__G_BATCH_EVAL_WITH_RESULT__#{body}",
                              session_id: current_session_id,
                              parent_id: callback_parent_id,
                              timeout: effective_bridge_timeout(timeout: nil))
      decode_batch_eval_payload(parsed)
    end

    # Single round-trip replacement for the two eval_r probes in
    # R::Support.process_missing_dispatch (is_field + is_func).
    # Gatekeeper: __G_DISPATCH_PROBE__|handle|name
    def dispatch_probe(handle, name)
      parsed = @client.eval_r("__G_DISPATCH_PROBE__|#{handle}|#{name}",
                              session_id: current_session_id,
                              parent_id: callback_parent_id,
                              timeout: effective_bridge_timeout(timeout: nil))
      unless parsed['kind'].to_s == 'dispatch_probe'
        raise "dispatch_probe: unexpected payload #{parsed.inspect}"
      end

      { is_field: parsed['is_field'], is_func: parsed['is_func'] }
    end

    # Ensure session-scoped environment exists and return its R env handle.
    def ensure_session_env(session_id = current_session_id)
      sid = session_id.to_s
      @client.eval_r("({ galaaz_ensure_session_env(#{sid.inspect}); 0L })",
                     session_id: current_session_id,
                     parent_id: callback_parent_id,
                     timeout: effective_bridge_timeout(timeout: nil))
      nil
    end

    # Assign value expression into session environment.
    # value_expr must be a valid R expression string.
    def assign_session(session_id, key, value_expr)
      sid = session_id.to_s
      k = key.to_s
      @client.eval_r("({ galaaz_assign_session(#{sid.inspect}, #{k.inspect}, { #{value_expr} }); 0L })",
                     session_id: current_session_id,
                     parent_id: callback_parent_id,
                     timeout: effective_bridge_timeout(timeout: nil))
      nil
    end

    # Get a value from session environment (parsed payload).
    def get_session(session_id, key)
      sid = session_id.to_s
      k = key.to_s
      @client.eval_r("galaaz_get_session(#{sid.inspect}, #{k.inspect})",
                     session_id: current_session_id,
                     parent_id: callback_parent_id,
                     timeout: effective_bridge_timeout(timeout: nil))
    end

    # Remove a key from session environment.
    def rm_session(session_id, key)
      sid = session_id.to_s
      k = key.to_s
      @client.eval_r("({ galaaz_rm_session(#{sid.inspect}, #{k.inspect}); 0L })",
                     session_id: current_session_id,
                     parent_id: callback_parent_id,
                     timeout: effective_bridge_timeout(timeout: nil))
      nil
    end

    def effective_bridge_timeout(timeout: nil)
      return timeout if timeout

      raw = ENV['GALAAZ_BRIDGE_TIMEOUT_SEC']
      return 60 if raw.nil?

      s = raw.to_s.strip
      return 60 if s.empty?

      Integer(s)
    rescue StandardError, ArgumentError
      60
    end

    # Phase 5.3 callback stub registration for R::Support.parse_arg.
    # Returns an R function string that forwards callback execution to Ruby
    # using the NewBridge CALL/RET path.
    def register_callback_proc_stub(proc_or_method)
      callback_session_id = current_session_id
      callback_wait_ms = begin
        raw = ENV.fetch('GALAAZ_CALLBACK_TIMEOUT_MS', '120000').to_s.strip
        v = Integer(raw)
        v > 0 ? v : 120_000
      rescue StandardError
        120_000
      end
      if ENV['GALAAZ_TIMEOUT_DEBUG']
        STDERR.puts "[TIMEOUT_DEBUG] NewBridgeAdapter.register_callback_proc_stub callback_wait_ms=#{callback_wait_ms} env_callback=#{ENV['GALAAZ_CALLBACK_TIMEOUT_MS'].inspect}"
        STDERR.flush
      end
      # Stable R-safe fragment for namespacing callback result keys (session + call id).
      sess_key = callback_session_id.to_s.gsub(/[^a-zA-Z0-9_]/, '_')
      callback_call_id = @client.register_callback do |payload, call_id|
        old = Thread.current[:galaaz_new_bridge_parent_id]
        old_session = Thread.current[:galaaz_new_bridge_session_id]
        Thread.current[:galaaz_new_bridge_parent_id] = call_id
        Thread.current[:galaaz_new_bridge_session_id] = callback_session_id
        @in_callback = true
        begin
          cb_args = callback_payload_to_r_objects(payload)
          # Legacy arity-2 procs (phase 5.3 specs): (first R arg or nil, Ruby CALL envelope id).
          # Knitr/RubyCallback use arity != 2 and receive call(*cb_args).
          ar = proc_or_method.respond_to?(:arity) ? proc_or_method.arity : 0
          raw = if ar == 2 && cb_args.size <= 1
                  proc_or_method.call(cb_args[0], call_id)
                else
                  proc_or_method.call(*cb_args)
                end
          # Semantic return value: store in session env.
          # Transport RET is ACK-only (SessionClient sends "1"); R stub reads env after CALL/RET.
          slot_key = "r_#{sess_key}_#{call_id.gsub('-', '_')}"
          rhs = raw.is_a?(String) ? raw : R::Support.parse_arg(raw)
          assign_session(callback_session_id, slot_key, rhs)
          # Semantic value is staged in session env; RET must be ACK-only (nil → transport "1").
          nil
        ensure
          @in_callback = false
          Thread.current[:galaaz_new_bridge_session_id] = old_session
          Thread.current[:galaaz_new_bridge_parent_id] = old
        end
      end

      # Each ... arg is assigned in session env under a temporary handle.
      # Names must be g2_v + digits
      # only — gatekeeper valid_bridge_handle_token rejects g2_v_cb_* (letters after g2_v), which
      # breaks dispatch_probe when Ruby wraps the handle as R::Object.
      "function(...) {
        args <- list(...)
        handles <- character(0)
        if (length(args) > 0L) {
          for (i in seq_along(args)) {
            h <- paste0('g2_v', as.integer(stats::runif(1, 1e7, 9e7 - 1L)), sprintf('%04d', as.integer(i)))
            galaaz_assign_session('#{callback_session_id}', h, args[[i]])
            cls <- paste(class(args[[i]]), collapse = ' ')
            handles <- c(handles, paste0(h, ':', cls))
          }
        }
        payload <- paste(handles, collapse = '|')
        gid <- '#{callback_call_id}'
        galaaz_callback_call_phase3(gid, payload, #{callback_wait_ms})
        sess <- '#{sess_key}'
        nm <- paste0('r_', sess, '_', gsub('-', '_', gid))
        sid <- '#{callback_session_id}'
        if (exists(nm, envir = galaaz_ensure_session_env(sid), inherits = FALSE)) {
          val <- galaaz_get_session(sid, nm)
          galaaz_rm_session(sid, nm)
          return(val)
        }
        stop('callback staged no semantic value in session env')
      }"
    end

    def close
      @client&.stop
      @ready = false
    end

    # Structural unboxing helpers (Phase 5.5 hardening):
    # Keep deep unboxing on explicit bridge reads instead of generic method-missing paths.
    def unbox_list_length(var_name)
      probe = probe_node_expr(var_name)
      probe[:length].to_i
    end

    def unbox_list_element(var_name, one_based_index)
      tmp = ::R::Support.generate_var_name
      probe = probe_node_expr("#{var_name}[[#{one_based_index}]]", assign_to: tmp)

      case probe[:kind]
      when 'null'
        nil
      when 'list'
        ::R::Object.build(tmp, nil, r_class: 'list')
      when 'scalar_integer'
        probe[:value]
      when 'scalar_double'
        probe[:value]
      when 'scalar_logical'
        probe[:value]
      when 'scalar_character'
        v = probe[:value]
        (v.is_a?(::String) && v =~ /^rb_obj_\d+$/) ? ::R::Support.get_ruby_object(v) : v
      else
        r_class = probe[:r_class].to_s.strip
        return nil if r_class == 'NULL'
        ::R::Object.build(tmp, nil, r_class: r_class.empty? ? 'unknown' : r_class)
      end
    end

    # Specialized bounded traversal for deep unboxing checks.
    # Walks nested list structures in one bridge call and reports whether limits were exceeded.
    # Returns:
    #   { status: :ok|:depth_limit|:node_limit, nodes: Integer, max_depth: Integer }
    def unbox_walk(var_name, max_depth:, max_nodes:)
      cmd = "__G_UNBOX_WALK__|#{var_name}|#{max_depth.to_i}|#{max_nodes.to_i}"
      parsed = @client.eval_r(cmd, session_id: current_session_id, parent_id: callback_parent_id, timeout: effective_bridge_timeout(timeout: nil))
      status =
        case parsed['status'].to_s
        when 'DEPTH' then :depth_limit
        when 'NODE' then :node_limit
        else :ok
        end
      { status: status, nodes: parsed['nodes'].to_i, max_depth: parsed['max_depth'].to_i }
    end

    # Specialized one-call materialization for nested list/scalar/null trees.
    # Returns:
    #   { status: :ok|:depth_limit|:node_limit|:unsupported, nodes:, max_depth:, value: }
    def unbox_materialize(var_name, max_depth:, max_nodes:)
      cmd = "__G_UNBOX_MATERIALIZE__|#{var_name}|#{max_depth.to_i}|#{max_nodes.to_i}"
      parsed = @client.eval_r(cmd, session_id: current_session_id, parent_id: callback_parent_id, timeout: effective_bridge_timeout(timeout: nil))
      status =
        case parsed['status'].to_s
        when 'DEPTH' then :depth_limit
        when 'NODE' then :node_limit
        when 'UNSUPPORTED' then :unsupported
        else :ok
        end
      { status: status, nodes: parsed['nodes'].to_i, max_depth: parsed['max_depth'].to_i, value: parsed['value'] }
    end

    # Unbox atomic vectors to Ruby Arrays.
    # Primary path: gatekeeper `__G_PULL_VECTOR__` (one round-trip for full vector).
    # Fallback: per-element scalar eval (complex types, older gatekeeper, errors).
    def pull_vector(var_name)
      begin
        raw = eval_pull_vector_payload(var_name)
        out = decode_pull_vector_bulk_payload(raw)
        return out unless out.nil?
      rescue NewBridge::SessionClient::RProcessError
        # Unsupported SEXP type, unknown handle, or legacy binary without pull_vector.
      end
      pull_vector_elementwise(var_name)
    end

    # Indexed vector unboxing helpers expected by R::Vector#unboxed_get.
    # offset is 0-based (Ruby index), R indexing is 1-based.
    def pull_integer_vector(var_name, _total_size, offset = 0, chunk_size = nil)
      chunk_size ||= 1
      start_1 = offset + 1
      begin
        raw = eval_pull_vector_payload(var_name, slice_start_1based: start_1, slice_count: chunk_size)
        out = decode_pull_vector_bulk_payload(raw, want_kind: 'integer_vector')
        return out if out.is_a?(Array) && out.size == chunk_size
      rescue NewBridge::SessionClient::RProcessError
      end
      pull_integer_vector_elementwise(var_name, offset, chunk_size)
    end

    def pull_double_vector(var_name, _total_size, offset = 0, chunk_size = nil)
      chunk_size ||= 1
      start_1 = offset + 1
      begin
        raw = eval_pull_vector_payload(var_name, slice_start_1based: start_1, slice_count: chunk_size)
        out = decode_pull_vector_bulk_payload(raw, want_kind: 'double_vector')
        return out if out.is_a?(Array) && out.size == chunk_size
      rescue NewBridge::SessionClient::RProcessError
      end
      pull_double_vector_elementwise(var_name, offset, chunk_size)
    end

    # Push Ruby numeric array values into an R numeric vector.
    # - ruby_array: Ruby Array of Numeric/nil (nil mapped to NA_real_)
    # - var_name: target R variable handle/name
    # - offset/total_size: when provided, writes a slice using 0-based offset
    def push_double_vector(ruby_array, var_name, offset = nil, _total_size = nil)
      values = Array(ruby_array)
      return nil if values.empty?

      serialized = values.map do |v|
        if v.nil?
          'NA_real_'
        elsif v.is_a?(Numeric)
          v.finite? ? v.to_f.to_s : 'NA_real_'
        else
          begin
            Float(v).to_s
          rescue StandardError
            'NA_real_'
          end
        end
      end.join(', ')

      if offset
        start_i = offset.to_i + 1
        end_i = offset.to_i + values.length
        @client.eval_r("({ #{var_name}[#{start_i}:#{end_i}] <- c(#{serialized}); 0L })",
                       session_id: current_session_id,
                       parent_id: callback_parent_id,
                       timeout: effective_bridge_timeout(timeout: nil))
      else
        @client.eval_r("({ #{var_name} <- c(#{serialized}); 0L })",
                       session_id: current_session_id,
                       parent_id: callback_parent_id,
                       timeout: effective_bridge_timeout(timeout: nil))
      end
      nil
    end

    # data.frame unboxing: Ruby hash { "colname" => [values...] }.
    #
    # Column-wise bulk path: assign each column to a temp `g2_v*` handle, then
    # `pull_vector` (uses `__G_PULL_VECTOR__` when supported). Per-cell scalar
    # evals are avoided for atomic columns; list / unsupported columns still
    # fall back inside `pull_vector`.
    def pull_dataframe(var_name)
      t = effective_bridge_timeout(timeout: nil)
      sid = current_session_id
      pid = callback_parent_id

      ncol = @client.eval_r("length(#{var_name})", session_id: sid, parent_id: pid, timeout: t)['value'].to_i
      return {} if ncol <= 0

      col_hash = {}

      (1..ncol).each do |i|
        col_name_parsed = @client.eval_r("names(#{var_name})[#{i}]", session_id: sid, parent_id: pid, timeout: t)
        col_name = col_name_parsed['value']
        col_name = col_name.to_s if col_name

        tmp = ::R::Support.generate_var_name
        @client.eval_r("({ #{tmp} <- #{var_name}[[#{i}]]; 0L })", session_id: sid, parent_id: pid, timeout: t)
        col_hash[col_name] = pull_vector(tmp)
      end

      col_hash
    end

    private

    # Decode CALL payload from register_callback_proc_stub R side (handle:class|...).
    def callback_payload_to_r_objects(payload)
      s = payload.to_s.strip
      return [] if s.empty?

      s.split('|').filter_map do |pair|
        next if pair.empty?

        handle, r_class = pair.split(':', 2)
        R::Object.build(handle, nil, r_class: r_class)
      end
    end

    def callback_parent_id
      Thread.current[:galaaz_new_bridge_parent_id]
    end

    def current_session_id
      Thread.current[:galaaz_new_bridge_session_id] || 'default'
    end

    def probe_node_expr(expr, assign_to: nil)
      sep = "\u001F"
      assign_line = assign_to ? "#{assign_to} <- (#{expr})" : nil
      gk_obj_line = assign_to ? ".gk_obj <- #{assign_to}" : ".gk_obj <- (#{expr})"
      r_code = <<~RCODE
        ({
          #{assign_line}
          #{gk_obj_line}
          .gk_sep <- "#{sep}"
          .gk_kind <- if (is.null(.gk_obj)) {
            "null"
          } else if (is.list(.gk_obj)) {
            "list"
          } else if (length(.gk_obj) == 1L && is.integer(.gk_obj)) {
            "scalar_integer"
          } else if (length(.gk_obj) == 1L && is.double(.gk_obj)) {
            "scalar_double"
          } else if (length(.gk_obj) == 1L && is.logical(.gk_obj)) {
            "scalar_logical"
          } else if (length(.gk_obj) == 1L && is.character(.gk_obj)) {
            "scalar_character"
          } else {
            "other"
          }
          .gk_len <- length(.gk_obj)
          .gk_cls <- paste(class(.gk_obj), collapse=" ")
          .gk_val <- ""
          if (.gk_kind == "scalar_integer") {
            .gk_val <- if (is.na(.gk_obj[[1]])) "__NA__" else as.character(.gk_obj[[1]])
          } else if (.gk_kind == "scalar_double") {
            .gk_val <- if (is.na(.gk_obj[[1]])) "__NA__" else as.character(.gk_obj[[1]])
          } else if (.gk_kind == "scalar_logical") {
            .gk_val <- if (is.na(.gk_obj[[1]])) "__NA__" else if (.gk_obj[[1]]) "TRUE" else "FALSE"
          } else if (.gk_kind == "scalar_character") {
            .gk_val <- if (is.na(.gk_obj[[1]])) "__NA__" else as.character(.gk_obj[[1]])
          }
          paste(.gk_kind, as.character(.gk_len), .gk_cls, .gk_val, sep=.gk_sep)
        })
      RCODE

      raw = @client.eval_r(r_code, session_id: current_session_id, parent_id: callback_parent_id, timeout: effective_bridge_timeout(timeout: nil))
      token = raw['value'].to_s
      parts = token.split(sep, 4)
      kind = parts[0].to_s
      len = parts[1].to_i
      r_class = parts[2].to_s
      raw_val = parts[3].to_s
      value =
        case kind
        when 'scalar_integer'
          raw_val == '__NA__' ? nil : raw_val.to_i
        when 'scalar_double'
          raw_val == '__NA__' ? nil : raw_val.to_f
        when 'scalar_logical'
          raw_val == '__NA__' ? nil : (raw_val == 'TRUE')
        when 'scalar_character'
          raw_val == '__NA__' ? nil : raw_val
        else
          nil
        end

      { kind: kind, length: len, r_class: r_class, value: value }
    end

    def format_scalar_print(parsed)
      kind = parsed['kind']
      val = parsed['value']
      case kind
      when 'integer', 'double'
        "[1] #{val.nil? ? 'NA' : val}"
      when 'logical'
        "[1] #{val.nil? ? 'NA' : (val ? 'TRUE' : 'FALSE')}"
      when 'character'
        "[1] \"#{unescape_scalar_character(val.to_s)}\""
      else
        parsed.to_s
      end
    end

    def decode_batch_eval_payload(parsed)
      raise "batch: expected Hash payload, got #{parsed.class}" unless parsed.is_a?(Hash)

      case parsed['kind'].to_s
      when 'batch_error'
        idx = parsed['index']
        idx = idx.to_i if idx && !idx.is_a?(Integer)
        msg = parsed['message'].to_s
        raise R::BatchEvaluationError.new(msg, idx)
      when 'batch_eval'
        Array(parsed['results']).map { |sub| to_legacy_envelope(sub) }
      else
        raise "batch: unknown payload kind #{parsed['kind'].inspect}"
      end
    end

    def to_legacy_envelope(parsed)
      ptype = parsed['type'].to_s
      val = parsed['value']
      case ptype
      when 'scalar_integer'
        { type: :scalar_integer, value: val }
      when 'scalar_double'
        { type: :scalar_double, value: val }
      when 'scalar_logical'
        { type: :scalar_logical, value: val }
      when 'scalar_character'
        { type: :scalar_character, value: val.nil? ? nil : unescape_scalar_character(val.to_s) }
      when 'scalar_symbol'
        { type: :scalar_symbol, value: val.to_s }
      when 'handle'
        wt = parsed['wrapper_tag']
        wt = nil if wt.nil? || wt.to_s.strip.empty?
        { type: :handle, handle: parsed['handle'].to_s, r_class: parsed['r_class'].to_s, wrapper_tag: wt&.to_s }
      else
        raise "Result protocol: unknown payload type #{parsed.inspect}"
      end
    end

    def unescape_scalar_character(str)
      str.to_s
         .gsub(/\\n/, "\n")
         .gsub(/\\"/, '"')
         .gsub(/\\\\/, "\\")
    end

    # Gatekeeper bulk vector read: `__G_PULL_VECTOR__|handle` or slice `|start|count` (1-based start).
    def eval_pull_vector_payload(var_name, slice_start_1based: nil, slice_count: nil)
      cmd =
        if slice_start_1based.nil?
          "__G_PULL_VECTOR__|#{var_name}"
        else
          "__G_PULL_VECTOR__|#{var_name}|#{slice_start_1based.to_i}|#{slice_count.to_i}"
        end
      @client.eval_r(cmd,
                     session_id: current_session_id,
                     parent_id: callback_parent_id,
                     timeout: effective_bridge_timeout(timeout: nil))
    end

    def vector_bulk_kind?(k)
      %w[integer_vector double_vector logical_vector character_vector].include?(k.to_s)
    end

    # Returns Ruby Array or nil if +parsed+ is not a bulk vector payload.
    def decode_pull_vector_bulk_payload(parsed, want_kind: nil)
      return nil unless parsed.is_a?(Hash)

      k = parsed['kind'].to_s
      return nil unless vector_bulk_kind?(k)
      return nil if want_kind && k != want_kind.to_s

      vals = Array(parsed['values'])
      case k
      when 'integer_vector', 'double_vector'
        vals
      when 'logical_vector'
        vals.map { |v| v.nil? ? R::NA : v }
      when 'character_vector'
        vals.map { |v| v.nil? ? nil : unescape_scalar_character(v.to_s) }
      else
        nil
      end
    end

    def pull_vector_elementwise(var_name)
      len = @client.eval_r("length(#{var_name})",
                           session_id: current_session_id,
                           parent_id: callback_parent_id,
                           timeout: effective_bridge_timeout(timeout: nil))['value'].to_i
      return [] if len <= 0

      (1..len).map do |i|
        parsed = @client.eval_r("#{var_name}[[#{i}]]",
                                session_id: current_session_id,
                                parent_id: callback_parent_id,
                                timeout: effective_bridge_timeout(timeout: nil))
        case parsed['kind']
        when 'integer', 'double', 'character'
          parsed['kind'] == 'character' ? unescape_scalar_character(parsed['value'].to_s) : parsed['value']
        when 'logical'
          parsed['value'].nil? ? R::NA : parsed['value']
        else
          parsed['value']
        end
      end
    end

    def pull_integer_vector_elementwise(var_name, offset, chunk_size)
      start_i = offset + 1
      end_i = offset + chunk_size
      (start_i..end_i).map do |i|
        parsed = @client.eval_r("#{var_name}[[#{i}]]",
                                session_id: current_session_id,
                                parent_id: callback_parent_id,
                                timeout: effective_bridge_timeout(timeout: nil))
        parsed['value']
      end
    end

    def pull_double_vector_elementwise(var_name, offset, chunk_size)
      start_i = offset + 1
      end_i = offset + chunk_size
      (start_i..end_i).map do |i|
        parsed = @client.eval_r("#{var_name}[[#{i}]]",
                                session_id: current_session_id,
                                parent_id: callback_parent_id,
                                timeout: effective_bridge_timeout(timeout: nil))
        parsed['value']
      end
    end

    def phase1_scalar_fallback_error?(error)
      msg = error.message.to_s.strip
      return true if msg =~ /\Aphase1 requires length-1 scalar\z/
      return true if msg =~ /\Aunsupported type\z/
      return true if msg =~ /payload_error\("phase1 requires length-1 scalar"\)/
      return true if msg =~ /payload_error\("unsupported type"\)/
      false
    end
  end
end

