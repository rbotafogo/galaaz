# frozen_string_literal: true

require 'singleton'
require_relative '../new_bridge'

module R
  # Phase 5.1 adapter: expose a minimal ShadowBridge-compatible surface
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
      @client.start
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
      raise unless e.message.to_s.include?('unsupported type')

      @client.eval_r("({ #{code}; 0L })", session_id: current_session_id, parent_id: callback_parent_id)
      ''
    end

    # Legacy-compatible envelope shape expected by existing bridge specs.
    # Supports scalar assignments used by current migration subset.
    def eval_r_with_result(assignment_code)
      m = assignment_code.to_s.strip.match(/\A(?:\.GlobalEnv\$)?(\w+)\s*<-\s*(.+)\z/m)
      return nil unless m

      var_name = m[1]
      expr = m[2]
      # Force scalar-success return from phase1 eval path while preserving assignment side effect.
      @client.eval_r("({ #{var_name} <- #{expr}; 0L })", session_id: current_session_id, parent_id: callback_parent_id)
      len = @client.eval_r("length(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value']

      if len == 1
        is_integer = @client.eval_r("is.integer(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value']
        is_double = @client.eval_r("is.double(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value']
        is_logical = @client.eval_r("is.logical(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value']
        is_character = @client.eval_r("is.character(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value']

        if is_integer || is_double || is_logical || is_character
          parsed = @client.eval_r(var_name, session_id: current_session_id, parent_id: callback_parent_id)
          return to_legacy_envelope(parsed, var_name)
        end
      end

      r_class = @client.eval_r("paste(class(#{var_name}), collapse=' ')", session_id: current_session_id, parent_id: callback_parent_id)['value']
      if r_class.nil? || r_class.to_s.strip.empty?
        r_class = @client.eval_r("typeof(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value']
      end
      { type: :handle, handle: var_name, r_class: r_class.to_s }
    end

    # Phase 5.3 callback stub registration for R::Support.parse_arg.
    # Returns an R function string that forwards callback execution to Ruby
    # using the NewBridge CALL/RET path.
    def register_callback_proc_stub(proc_or_method)
      callback_session_id = current_session_id
      callback_call_id = @client.register_callback do |_payload, call_id|
        payload = _payload
        old = Thread.current[:galaaz_new_bridge_parent_id]
        old_session = Thread.current[:galaaz_new_bridge_session_id]
        Thread.current[:galaaz_new_bridge_parent_id] = call_id
        Thread.current[:galaaz_new_bridge_session_id] = callback_session_id
        @in_callback = true
        begin
          arity = proc_or_method.respond_to?(:arity) ? proc_or_method.arity : 0
          if arity == 0
            proc_or_method.call
          elsif arity == 1 || arity.negative?
            proc_or_method.call(payload)
          else
            proc_or_method.call(payload, call_id)
          end
        ensure
          @in_callback = false
          Thread.current[:galaaz_new_bridge_session_id] = old_session
          Thread.current[:galaaz_new_bridge_parent_id] = old
        end
      end

      "function(...) {
        args <- list(...)
        payload <- ''
        if (length(args) >= 1L) {
          a <- args[[1]]
          if (length(a) == 1L && (is.character(a) || is.numeric(a) || is.logical(a))) {
            payload <- as.character(a)
          }
        }
        galaaz_callback_call_phase3('#{callback_call_id}', payload, 5000)
      }"
    end

    def close
      @client&.stop
      @ready = false
    end

    # Structural unboxing helpers (Phase 5.5 hardening):
    # Keep deep unboxing on explicit bridge reads instead of generic method-missing paths.
    def unbox_list_length(var_name)
      @client.eval_r("length(#{var_name})", session_id: current_session_id, parent_id: callback_parent_id)['value'].to_i
    end

    def unbox_list_element(var_name, one_based_index)
      tmp = ::R::Support.generate_var_name
      @client.eval_r("({ #{tmp} <- #{var_name}[[#{one_based_index}]]; 0L })",
                     session_id: current_session_id, parent_id: callback_parent_id)
      return nil if @client.eval_r("is.null(#{tmp})",
                                   session_id: current_session_id, parent_id: callback_parent_id)['value']

      if @client.eval_r("is.list(#{tmp})",
                        session_id: current_session_id, parent_id: callback_parent_id)['value']
        return ::R::Object.build(tmp, nil, r_class: 'list')
      end

      len = @client.eval_r("length(#{tmp})",
                           session_id: current_session_id, parent_id: callback_parent_id)['value'].to_i
      if len == 1
        parsed = @client.eval_r(tmp,
                                session_id: current_session_id, parent_id: callback_parent_id)
        case parsed['kind']
        when 'integer', 'double', 'logical', 'character'
          v = parsed['value']
          return (v.is_a?(::String) && v =~ /^rb_obj_\d+$/) ? ::R::Support.get_ruby_object(v) : v
        when 'symbol'
          return parsed['value']
        end
      end

      r_class = @client.eval_r("paste(class(#{tmp}), collapse=' ')",
                               session_id: current_session_id, parent_id: callback_parent_id)['value']
      r_class = @client.eval_r("typeof(#{tmp})",
                               session_id: current_session_id, parent_id: callback_parent_id)['value'] if r_class.nil? || r_class.to_s.strip.empty?
      return nil if r_class.to_s.strip == 'NULL'
      ::R::Object.build(tmp, nil, r_class: r_class.to_s)
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
          parsed['value']
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

    def callback_parent_id
      Thread.current[:galaaz_new_bridge_parent_id]
    end

    def current_session_id
      Thread.current[:galaaz_new_bridge_session_id] || 'default'
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
        "[1] \"#{val}\""
      else
        parsed.to_s
      end
    end

    def to_legacy_envelope(parsed, var_name)
      kind = parsed['kind']
      val = parsed['value']
      case kind
      when 'integer'
        { type: :scalar_integer, value: val }
      when 'double'
        { type: :scalar_double, value: val }
      when 'logical'
        { type: :scalar_logical, value: val }
      when 'character'
        { type: :scalar_character, value: val }
      else
        { type: :handle, handle: var_name, r_class: kind.to_s }
      end
    end
  end
end

