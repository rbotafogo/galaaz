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

      # Compatibility with the legacy ShadowBridge setup:
      # - `R.awt` / X11 for plotting (examples/sthda_ggplot).
      # - `missing_arg()` for Ruby :all in `[` / tbl subset (R::Support.parse_arg).
      #   Use rlang::missing_arg when available: tibble/tidyselect reject the legacy
      #   quote(f(,0))[[2]] sentinel ("Subscript ... can't contain the empty string").
      # The gatekeeper evaluates each REQ in a dedicated per-session env; globals are shared.
      @client.eval_r(
        <<~RCODE,
          ({
            assign('awt', function(...) { X11(...) }, envir = .GlobalEnv)
            if (requireNamespace('rlang', quietly = TRUE)) {
              assign('missing_arg', getExportedValue('rlang', 'missing_arg'), envir = .GlobalEnv)
            } else {
              assign('missing_arg', function() { quote(f(,0))[[2]] }, envir = .GlobalEnv)
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
                nm <- paste0('galaaz_session_env_', gsub('[^A-Za-z0-9_]', '_', sid))
                if (!exists(nm, envir = .GlobalEnv, inherits = FALSE)) {
                  assign(nm, new.env(parent = emptyenv()), envir = .GlobalEnv)
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
        parent_id: callback_parent_id
      )
      @ready = true
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
    def eval_r(code)
      out = @client.eval_r(code, session_id: current_session_id, parent_id: callback_parent_id)
      format_scalar_print(out)
    rescue NewBridge::SessionClient::RProcessError => e
      # Phase 5.3 compatibility: many eval_r call sites are side-effect only
      # (e.g. function definitions) and do not require a scalar return value.
      # The phase1 gatekeeper returns "unsupported type" for non-scalars, so
      # run in side-effect mode and return an empty string.
      msg = e.message.to_s
      raise unless msg.include?('unsupported type') || msg.include?('phase1 requires length-1 scalar')

      @client.eval_r("({ #{code}; 0L })", session_id: current_session_id, parent_id: callback_parent_id)
      ''
    end

    # Return the printed representation of an R object as a Ruby string.
    def print_r(var_name)
      parsed = @client.eval_r("paste(capture.output(print(#{var_name})), collapse='\\n')",
                              session_id: current_session_id,
                              parent_id: callback_parent_id)
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
                              parent_id: callback_parent_id)
      to_legacy_envelope(parsed)
    end

    # Single round-trip replacement for the two eval_r probes in
    # R::Support.process_missing_dispatch (is_field + is_func).
    # Gatekeeper: __G_DISPATCH_PROBE__|handle|name
    def dispatch_probe(handle, name)
      parsed = @client.eval_r("__G_DISPATCH_PROBE__|#{handle}|#{name}",
                              session_id: current_session_id,
                              parent_id: callback_parent_id)
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
                     parent_id: callback_parent_id)
      nil
    end

    # Assign value expression into session environment.
    # value_expr must be a valid R expression string.
    def assign_session(session_id, key, value_expr)
      sid = session_id.to_s
      k = key.to_s
      @client.eval_r("({ galaaz_assign_session(#{sid.inspect}, #{k.inspect}, { #{value_expr} }); 0L })",
                     session_id: current_session_id,
                     parent_id: callback_parent_id)
      nil
    end

    # Get a value from session environment (parsed payload).
    def get_session(session_id, key)
      sid = session_id.to_s
      k = key.to_s
      @client.eval_r("galaaz_get_session(#{sid.inspect}, #{k.inspect})",
                     session_id: current_session_id,
                     parent_id: callback_parent_id)
    end

    # Remove a key from session environment.
    def rm_session(session_id, key)
      sid = session_id.to_s
      k = key.to_s
      @client.eval_r("({ galaaz_rm_session(#{sid.inspect}, #{k.inspect}); 0L })",
                     session_id: current_session_id,
                     parent_id: callback_parent_id)
      nil
    end

    # Phase 5.3 callback stub registration for R::Support.parse_arg.
    # Returns an R function string that forwards callback execution to Ruby
    # using the NewBridge CALL/RET path.
    def register_callback_proc_stub(proc_or_method)
      callback_session_id = current_session_id
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

      # Each ... arg is assigned in .GlobalEnv under a temporary handle for compatibility.
      # TODO (Phase 3): move handle resolution fully to session env once dispatch paths stop relying on global lookup.
      # Names must be g2_v + digits
      # only — gatekeeper valid_bridge_handle_token rejects g2_v_cb_* (letters after g2_v), which
      # breaks dispatch_probe when Ruby wraps the handle as R::Object.
      "function(...) {
        args <- list(...)
        handles <- character(0)
        created_handles <- character(0)
        on.exit({
          if (length(created_handles) > 0L) {
            try(base::rm(list = created_handles, envir = .GlobalEnv, inherits = FALSE), silent = TRUE)
          }
        }, add = TRUE)
        if (length(args) > 0L) {
          for (i in seq_along(args)) {
            h <- paste0('g2_v', as.integer(stats::runif(1, 1e7, 9e7 - 1L)), sprintf('%04d', as.integer(i)))
            assign(h, args[[i]], envir = .GlobalEnv)
            created_handles <- c(created_handles, h)
            cls <- paste(class(args[[i]]), collapse = ' ')
            handles <- c(handles, paste0(h, ':', cls))
          }
        }
        payload <- paste(handles, collapse = '|')
        gid <- '#{callback_call_id}'
        galaaz_callback_call_phase3(gid, payload, 5000)
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
      parsed = @client.eval_r(cmd, session_id: current_session_id, parent_id: callback_parent_id)
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
      parsed = @client.eval_r(cmd, session_id: current_session_id, parent_id: callback_parent_id)
      status =
        case parsed['status'].to_s
        when 'DEPTH' then :depth_limit
        when 'NODE' then :node_limit
        when 'UNSUPPORTED' then :unsupported
        else :ok
        end
      { status: status, nodes: parsed['nodes'].to_i, max_depth: parsed['max_depth'].to_i, value: parsed['value'] }
    end

    # Minimal pull path for Phase 5.1 unboxing support.
    # Reads vectors element-by-element via the existing eval path.
    def pull_vector(var_name)
      len = @client.eval_r("length(#{var_name})", session_id: current_session_id)['value'].to_i
      return [] if len <= 0

      (1..len).map do |i|
        parsed = @client.eval_r("#{var_name}[[#{i}]]", session_id: current_session_id)
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

    # Indexed vector unboxing helpers expected by R::Vector#unboxed_get.
    # offset is 0-based (Ruby index), R indexing is 1-based.
    def pull_integer_vector(var_name, _total_size, offset = 0, chunk_size = nil)
      chunk_size ||= 1
      start_i = offset + 1
      end_i = offset + chunk_size
      (start_i..end_i).map do |i|
        parsed = @client.eval_r("#{var_name}[[#{i}]]", session_id: current_session_id)
        parsed['value']
      end
    end

    def pull_double_vector(var_name, _total_size, offset = 0, chunk_size = nil)
      chunk_size ||= 1
      start_i = offset + 1
      end_i = offset + chunk_size
      (start_i..end_i).map do |i|
        parsed = @client.eval_r("#{var_name}[[#{i}]]", session_id: current_session_id)
        parsed['value']
      end
    end

    # Minimal data.frame unboxing for Phase 5.2.
    # Returns a Ruby hash: { "colname" => [values...] }.
    #
    # Uses scalar eval for each cell to stay compatible with phase1's
    # length-1 scalar limitation.
    def pull_dataframe(var_name)
      ncol = @client.eval_r("length(#{var_name})", session_id: current_session_id)['value'].to_i
      return {} if ncol <= 0

      col_hash = {}

      (1..ncol).each do |i|
        # names(df)[i] is a character vector of length 1 -> length-1 scalar.
        col_name_parsed = @client.eval_r("names(#{var_name})[#{i}]", session_id: current_session_id)
        col_name = col_name_parsed['value']
        col_name = col_name.to_s if col_name

        col_type = @client.eval_r("typeof(#{var_name}[[#{i}]])", session_id: current_session_id)['value'].to_s
        nrow = @client.eval_r("length(#{var_name}[[#{i}]])", session_id: current_session_id)['value'].to_i
        nrow = 0 if nrow.negative?

        values = (1..nrow).map do |j|
          parsed = @client.eval_r("#{var_name}[[#{i}]][[#{j}]]", session_id: current_session_id)
          case parsed['kind']
          when 'logical'
            parsed['value'].nil? ? R::NA : parsed['value']
          when 'integer', 'double', 'character'
            parsed['value']
          else
            parsed['value']
          end
        end

        col_hash[col_name] = values
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

      raw = @client.eval_r(r_code, session_id: current_session_id, parent_id: callback_parent_id)
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
        { type: :handle, handle: parsed['handle'].to_s, r_class: parsed['r_class'].to_s }
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
  end
end

