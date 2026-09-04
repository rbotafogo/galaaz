# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'socket'
require 'tmpdir'
require 'timeout'

require_relative 'envelope'
require_relative 'eval_result'
require_relative 'framing'

module NewBridge
  # Pending async +eval_r_async+ entry: completion runs on a background thread (not the reader).
  class AsyncPendingEntry
    attr_reader :instance_id, :block
    attr_accessor :timer_thread

    def initialize(instance_id, block)
      @instance_id = instance_id
      @block = block
      @timer_thread = nil
    end

    def cancel_timer!
      t = @timer_thread
      return unless t&.alive?
      return if Thread.current.equal?(t)

      t.kill
      t.join(0.05)
    rescue StandardError
      nil
    end
  end

  # NewBridge::SessionClient
  #
  # Responsibilities (Ruby side, inside one Ruby process):
  # - Accept one connection from the R gatekeeper (Unix socket or TCP).
  # - Serialize and send framed MsgPack envelopes of type `REQ`.
  # - Wait for matching framed MsgPack envelopes of type `RET`.
  # - Handle R -> Ruby callback requests (`CALL`) by invoking registered Ruby
  #   blocks in background threads and replying with `RET`.
  #
  # Protocol basics
  # - Transport: Unix domain socket for local R (loopback), TCP when R connects to a non-local host
  #   (e.g. Docker). Override with ENV['GALAAZ_BRIDGE_TRANSPORT'] = unix|tcp. Same MsgPack framing.
  # - Envelopes are MsgPack maps handled by `NewBridge::Envelope`.
  # - Envelope fields used here:
  #   - `call_id`: UUID used to correlate one REQ with one RET
  #   - `type`: `"REQ"` / `"RET"` / `"CALL"`
  #   - `session_id`: logical session; R uses it to isolate per-session env state
  #   - `instance_id`: logical instance routing; used for multi-instance pools
  #   - `parent_id`: reserved for nested-call correlation (Phase 4+)
  #
  # Threading model
  # - One reader thread (`reader_loop`) continuously reads frames and dispatches:
  #   - `RET` -> pushes into the per-call Queue (sync +eval_r+) or schedules async completion (+eval_r_async+)
  #   - `CALL` -> spawns a new thread to execute the Ruby callback
  # - Callback threads send `RET` back to R while keeping the reader thread free,
  #   which is required to support nested REQ servicing while waiting for a callback.
  #
  # Failure behavior
  # - If the socket closes or a read error happens, pending REQ calls are signaled
  #   as closed and subsequent eval calls raise.
  # - Infrastructure failures (timeouts / broken pipes / connection reset) are
  #   handled at a higher level by `RInstanceManager` restart+retry logic.
  class SessionClient
    class Error < StandardError; end
    class TimeoutError < Error; end
    class RProcessError < Error; end

    attr_reader :r_stderr, :r_exit_status

    # Create a SessionClient for one R runtime instance.
    #
    # @param source_path [String] Host-side path to .cpp or .so for Rcpp `sourceCpp`/`dyn.load`.
    # @param host [String] bind/listen address for Ruby TCP server.
    # @param bridge_host [String,nil] host name/path R uses to connect to this Ruby listener (defaults to +host+).
    #   For containerized R, set to the host reachable from the container (e.g. host.docker.internal).
    # @param runtime_source_path [String,nil] source path visible from runtime process/container.
    # @param use_unix [Boolean,nil] force Unix (true) or TCP (false). Default nil: auto — Unix for local
    #   loopback targets, TCP for remote/non-loopback +bridge_host+.
    # @param r_cmd [String, Array<String>] executable (or argv prefix ending with executable).
    def initialize(source_path:, host: '127.0.0.1', bridge_host: nil, runtime_source_path: nil, r_cmd: 'R',
                   use_unix: nil)
      @source_path = File.expand_path(source_path)
      @use_precompiled = @source_path.end_with?('.so')
      @host = host
      @bridge_host = bridge_host || host
      @runtime_source_path = runtime_source_path || @source_path
      @r_cmd = r_cmd
      @use_unix = if use_unix.nil?
                    self.class.default_use_unix?(bridge_target: @bridge_host)
                  else
                    use_unix
                  end
      @unix_path = nil
      @server = nil
      @sock = nil
      @write_mx = Mutex.new
      @pending = {}
      @pending_mx = Mutex.new
      @callbacks = {}
      @callbacks_mx = Mutex.new
      @reader = nil
      @r_stderr = +''
      @r_stderr_mx = Mutex.new
      @r_stderr_limit = 64 * 1024
      @r_exit_status = nil
      @r_wait_thr = nil
      @r_thr = nil
    end

    # Whether to use Unix domain sockets for this client when +use_unix+ is nil.
    #
    # Policy:
    # - +GALAAZ_BRIDGE_TRANSPORT=tcp+ — always TCP (remote R, or debugging).
    # - +GALAAZ_BRIDGE_TRANSPORT=unix+ — always Unix when supported.
    # - Otherwise: Unix only if +bridge_target+ is a local loopback address/name (127.0.0.1, ::1, localhost)
    #   or a Unix socket path (+#+). Any other host (e.g. +host.docker.internal+, LAN IP) uses TCP so R can
    #   reach Ruby over the network.
    #
    # @param bridge_target [String] resolved +bridge_host+ passed to R (+galaaz_run_bridge+).
    def self.default_use_unix?(bridge_target:)
      return false unless defined?(UNIXServer)

      case ENV['GALAAZ_BRIDGE_TRANSPORT'].to_s.downcase
      when 'tcp'
        false
      when 'unix'
        true
      else
        t = bridge_target.to_s.strip
        if t.empty?
          false
        elsif t.start_with?('/')
          true
        else
          u = t.downcase
          %w[127.0.0.1 ::1 localhost].include?(u)
        end
      end
    end

    # Start listening for a single TCP connection from one R process and launch that process.
    #
    # - Binds to an ephemeral TCP port, or a Unix socket path when +use_unix+ is set.
    # - Starts a thread that runs `r_cmd` and sources the gatekeeper C++ code inside R.
    # - Accepts the runtime connection with `accept_timeout`.
    #
    # On startup failure (e.g. runtime exits before connecting), it surfaces R stderr and exit status.
    def start(accept_timeout: 120)
      use_u = @use_unix && defined?(UNIXServer)
      if @use_unix && !defined?(UNIXServer)
        warn '[NewBridge::SessionClient] Unix bridge transport selected but UNIXServer is unavailable; falling back to TCP'
        use_u = false
      end

      if use_u
        @unix_path = File.join(Dir.tmpdir, "galaaz_bridge_#{Process.pid}_#{SecureRandom.hex(6)}.sock")
        File.unlink(@unix_path) if File.exist?(@unix_path)
        @server = UNIXServer.new(@unix_path)
        port = 0
        bridge_for_r = @unix_path.gsub("'", "\\\\'")
      else
        @server = TCPServer.new(@host, 0)
        port = @server.addr[1]
        bridge_for_r = @bridge_host.gsub("'", "\\\\'")
      end

      # Use sourceCpp with a persistent cache directory so repeated runtime
      # starts can reuse compiled shared objects when source is unchanged.
      cpp_escaped = @runtime_source_path.gsub("'", "\\\\'")
      rcpp_cache_dir = (ENV['GALAAZ_RCPP_CACHE_DIR'] || File.join(Dir.tmpdir, 'galaaz_rcpp_cache')).gsub("'", "\\\\'")
      r_script = <<~R
        bridge_host <- '#{bridge_for_r}'
        port <- #{port}L
        stopifnot(requireNamespace("Rcpp", quietly = TRUE))
        library(Rcpp)
        dir.create("#{rcpp_cache_dir}", recursive = TRUE, showWarnings = FALSE)
        sourceCpp(file = "#{cpp_escaped}", rebuild = FALSE, cacheDir = "#{rcpp_cache_dir}")
        galaaz_run_bridge(bridge_host, as.integer(port))
      R

      env = if use_u
              { 'GALAAZ_BRIDGE_HOST' => @unix_path, 'GALAAZ_BRIDGE_PORT' => '0', 'GALAAZ_BRIDGE_UNIX' => '1' }
            else
              { 'GALAAZ_BRIDGE_HOST' => @bridge_host, 'GALAAZ_BRIDGE_PORT' => port.to_s }
            end
      @r_thr = Thread.new do
        launch = @r_cmd.is_a?(Array) ? @r_cmd.dup : [@r_cmd]
        _stdin, stdout_err, wait_thr = Open3.popen2e(env, *launch, '--slave', '--no-save', '-e', r_script)
        @r_wait_thr = wait_thr
        # When the R process exits or during shutdown, the underlying pipe can
        # close while this background thread is still blocked reading.
        # Treat that as a normal shutdown and avoid JRuby "stream closed in
        # another thread" warnings.
        begin
          stdout_err.each_line { |line| append_r_stderr(line) }
        rescue IOError, Errno::EPIPE, Errno::ECONNRESET
          # normal shutdown / pipe closure
        end
        @r_exit_status = wait_thr.value
      end

      @sock = Timeout.timeout(accept_timeout) { @server.accept }
      @reader = Thread.new { reader_loop }
      self
    rescue Timeout::Error
      # If the runtime process failed early (e.g. docker permission/network/source path),
      # surface stderr/exit details instead of a generic accept timeout.
      process_status = @r_exit_status&.exitstatus
      details = current_r_stderr
      msg = "failed to accept runtime connection within #{accept_timeout}s"
      msg += " (runtime exit=#{process_status})" if process_status
      unless details.empty?
        tail = details.length > 2000 ? details[-2000, 2000] : details
        msg += " stderr_tail=#{tail}"
      end
      kill_runtime_process!
      raise RProcessError, msg
    end

    # Hard-stop the R child (e.g. after an eval timeout while install.packages is still compiling).
    # Without this, R keeps building packages and can OOM the host shell/VM.
    def kill_runtime_process!
      thr = @r_wait_thr
      pid = begin
        thr&.pid
      rescue StandardError
        nil
      end
      if pid
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH, Errno::EPERM
          nil
        end
        sleep 0.2
        begin
          Process.kill('KILL', pid)
        rescue Errno::ESRCH, Errno::EPERM
          nil
        end
      end
    ensure
      @r_wait_thr = nil
    end

    # Stop the client and attempt to join threads cleanly.
    # Best-effort: socket/server are closed, reader thread is joined, runtime thread is joined.
    def stop
      kill_runtime_process!
      @sock&.close rescue nil
      @server&.close rescue nil
      if @unix_path && File.socket?(@unix_path)
        File.unlink(@unix_path) rescue nil
      end
      @unix_path = nil
      @reader&.join(3)
      @r_thr&.join(15)
    end

    # Kill R + reopen listener/runtime. Clears pending queues.
    def restart!(accept_timeout: 120)
      stop
      @pending_mx.synchronize { @pending.clear }
      @callbacks_mx.synchronize { @callbacks.clear }
      @r_stderr_mx.synchronize { @r_stderr = +'' }
      @r_exit_status = nil
      @reader = nil
      @r_thr = nil
      @sock = nil
      @server = nil
      start(accept_timeout: accept_timeout)
    end

    # Evaluate one REQ on the connected R runtime and wait for the matching RET.
    #
    # @param code [String] R expression or snippet to be evaluated by the gatekeeper.
    # @param session_id [String] session env isolation key (maps to R's `.galaaz_sessions`).
    # @param instance_id [String] instance routing key (must match RInstanceManager routing).
    # @param parent_id [String,nil] reserved for nested-call correlation (Phase 4+).
    # @param timeout [Numeric] how long to wait for RET before raising TimeoutError.
    #
    # @return [Hash] decoded MsgPack payload map returned by gatekeeper on success.
    def eval_r(code, session_id: 'default', instance_id: 'default', parent_id: nil, timeout: 60)
      call_id = SecureRandom.uuid
      q = Queue.new
      @pending_mx.synchronize { @pending[call_id] = q }
      req = Envelope.encode(
        'call_id' => call_id,
        'type' => 'REQ',
        'session_id' => session_id,
        'instance_id' => instance_id,
        'parent_id' => parent_id,
        'payload' => code
      )
      @write_mx.synchronize { Framing.write_frame(@sock, req) }

      ret = wait_for_ret(q, call_id, timeout)
      if ret['instance_id'] && ret['instance_id'] != instance_id
        raise RProcessError, "instance_id mismatch: expected=#{instance_id} got=#{ret['instance_id']}"
      end
      status = ret['status']
      payload = ret['payload']
      unless payload.is_a?(Hash)
        raise RProcessError, "invalid RET payload type=#{payload.class} (expected map)"
      end
      parsed = payload
      raise RProcessError, parsed['message'] || parsed.inspect unless status == 'success'

      parsed
    end

    # Schedule one REQ and invoke +block+ on a background thread when RET arrives (or on failure).
    #
    # Unlike +eval_r+, this method returns immediately with the +call_id+ String; it does not wait
    # for R unless +timeout+ is nil (wait forever on the Ruby side for RET) or a Numeric (raise
    # completion with {TimeoutError} if RET is late).
    #
    # @param timeout [nil, Numeric] +nil+ means no limit; a positive number starts a timer thread.
    # @return [String] +call_id+ for correlation / debugging
    # @raise [ArgumentError] if no block is given
    def eval_r_async(code, session_id: 'default', instance_id: 'default', parent_id: nil, timeout: nil, &block)
      raise ArgumentError, 'eval_r_async requires a block' unless block

      call_id = SecureRandom.uuid
      slot = AsyncPendingEntry.new(instance_id, block)
      @pending_mx.synchronize { @pending[call_id] = slot }

      req = Envelope.encode(
        'call_id' => call_id,
        'type' => 'REQ',
        'session_id' => session_id,
        'instance_id' => instance_id,
        'parent_id' => parent_id,
        'payload' => code
      )
      @write_mx.synchronize { Framing.write_frame(@sock, req) }

      if timeout
        slot.timer_thread = Thread.new { async_timeout_wait(call_id, slot, timeout) }
      end

      call_id
    end

    # Register a Ruby callback for R->Ruby `CALL` envelopes.
    #
    # The gatekeeper will invoke this callback when it receives a `CALL` with the
    # corresponding `callback_call_id`, and this client will reply with a `RET`.
    # The same `call_id` may be used many times (R stub function is reused); the block
    # stays registered until the client stops — do not delete on first CALL.
    def register_callback(&block)
      callback_call_id = SecureRandom.uuid
      @callbacks_mx.synchronize { @callbacks[callback_call_id] = block }
      callback_call_id
    end

    private

    # Gatekeeper parses RET success payload with strtod. Contract:
    # - `register_callback_proc_stub` ends with nil → ACK "1" (semantic value staged in R).
    # - Direct `register_callback` blocks may return a Numeric scalar; pass it through for legacy tests.
    def self.callback_success_transport_payload(result)
      case result
      when nil
        '1'
      when Numeric
        x = result.to_f
        (x.nan? || x.infinite?) ? '0' : x.to_s
      when true
        '1'
      when false
        '0'
      else
        '1'
      end
    end

    # Emit debug logs when GALAAZ_DEBUG is set.
    def debug_log(msg)
      return unless ENV['GALAAZ_DEBUG']
      STDERR.puts("[NewBridge::SessionClient] #{msg}")
      STDERR.flush
    end

    # Wait for RET for one `call_id` by popping from queue `q`.
    # On timeout it removes the pending queue and raises TimeoutError.
    def wait_for_ret(q, call_id, timeout)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Timeout.timeout(timeout) do
        v = q.pop
        raise RProcessError, 'R connection closed' if v == :closed

        v
      end
    rescue Timeout::Error
      @pending_mx.synchronize { @pending.delete(call_id) }
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      raise TimeoutError, format('no RET for %<id>s (timeout=%<timeout>.3fs elapsed=%<elapsed>.3fs)', id: call_id, timeout: timeout.to_f, elapsed: elapsed)
    end

    # Reader loop running in a background thread:
    # - reads framed envelopes
    # - dispatches by `type`
    # - shields the main eval path from socket read latency
    def reader_loop
      loop do
        bytes = Framing.read_frame(@sock)
        h = Envelope.decode(bytes)
        debug_log("RX type=#{h['type']} call_id=#{h['call_id']} session_id=#{h['session_id']} instance_id=#{h['instance_id']}") if h.is_a?(Hash)
        case h['type']
        when 'RET'
          entry = @pending_mx.synchronize { @pending.delete(h['call_id']) }
          case entry
          when Queue
            entry.push(h)
          when AsyncPendingEntry
            entry.cancel_timer!
            Thread.new { deliver_eval_r_async_completion(entry, h) }
          when nil
            debug_log("stray RET call_id=#{h['call_id']}")
          else
            debug_log("unexpected pending type=#{entry.class} call_id=#{h['call_id']}")
          end
        when 'CALL'
          handle_call(h)
        end
      end
    rescue Framing::TruncatedFrame, Framing::Error, IOError, Errno::ECONNRESET, Errno::EPIPE, Envelope::Error
      signal_closed
    end

    # Handle one R->Ruby callback request:
    # - look up the Ruby callback by `call_id`
    # - execute it in a new thread
    # - send RET back with status success/error
    def handle_call(h)
      call_id = h['call_id']
      instance_id = h['instance_id'] || 'default'
      payload = h['payload']
      debug_log("CALL received call_id=#{call_id} instance_id=#{instance_id} payload=#{payload.inspect}")

      callback = @callbacks_mx.synchronize { @callbacks[call_id] }
      unless callback
        send_ret(call_id: call_id, status: 'error', payload: "unknown callback #{call_id}", instance_id: instance_id)
        return
      end

      # Phase 4: Run callback in separate thread so reader thread stays free
      # for nested REQ/RET handling
      Thread.new do
        begin
          result = callback.call(payload, call_id)
          debug_log("CALL result call_id=#{call_id} result=#{result.inspect}")
          payload_txt = self.class.callback_success_transport_payload(result)
          send_ret(call_id: call_id, status: 'success', payload: payload_txt, instance_id: instance_id)
        rescue IOError, Errno::EPIPE => e
          # Socket closed - ignore, connection is shutting down
          debug_log("CALL send failed (socket closed) call_id=#{call_id}: #{e.message}")
        rescue => e
          debug_log("CALL error call_id=#{call_id} error=#{e.class}: #{e.message}")
          begin
            send_ret(call_id: call_id, status: 'error', payload: e.message, instance_id: instance_id)
          rescue IOError, Errno::EPIPE
              # Socket closed - ignore
          end
        end
      end
    end

    # Send RET envelope for a CALL.
    # Payload is encoded as a simple string (`result.to_s` or exception message),
    # and gatekeeper converts it back into its expected scalar type.
    def send_ret(call_id:, status:, payload:, instance_id:)
      debug_log("TX RET call_id=#{call_id} instance_id=#{instance_id} status=#{status} payload=#{payload.inspect}")
      ret = Envelope.encode(
        'call_id' => call_id,
        'type' => 'RET',
        'status' => status,
        'payload' => payload,
        'instance_id' => instance_id,
        'parent_id' => nil
      )
      @write_mx.synchronize { Framing.write_frame(@sock, ret) }
    end

    # Signal all pending eval_r requests that the socket is closed,
    # allowing waiting `eval_r` calls to raise promptly.
    def signal_closed
      entries = @pending_mx.synchronize do
        e = @pending.dup
        @pending.clear
        e
      end
      entries.each do |_call_id, entry|
        case entry
        when Queue
          entry.push(:closed)
        when AsyncPendingEntry
          entry.cancel_timer!
          Thread.new { invoke_async_block_safe(entry, EvalResult.failure(RProcessError.new('R connection closed'))) }
        else
          debug_log("signal_closed: skip pending type=#{entry.class}")
        end
      end
    end

    def ret_hash_to_eval_result(ret, expected_instance_id)
      unless ret.is_a?(Hash)
        return EvalResult.failure(RProcessError.new("invalid RET payload type=#{ret.class}"))
      end

      if ret['instance_id'] && ret['instance_id'] != expected_instance_id
        return EvalResult.failure(RProcessError.new("instance_id mismatch: expected=#{expected_instance_id} got=#{ret['instance_id']}"))
      end

      payload = ret['payload']
      unless payload.is_a?(Hash)
        return EvalResult.failure(RProcessError.new("invalid RET payload inner type=#{payload.class} (expected map)"))
      end

      return EvalResult.failure(RProcessError.new(payload['message'] || payload.inspect)) if ret['status'] != 'success'

      EvalResult.success(payload)
    end

    def deliver_eval_r_async_completion(slot, ret_env)
      result = ret_hash_to_eval_result(ret_env, slot.instance_id)
      invoke_async_block_safe(slot, result)
    end

    def invoke_async_block_safe(slot, result)
      slot.block.call(result)
    rescue StandardError => e
      debug_log("eval_r_async block raised #{e.class}: #{e.message}")
      raise if ENV['GALAAZ_ASYNC_RAISE_COMPLETION']

      nil
    end

    def async_timeout_wait(call_id, slot, timeout)
      sleep(timeout.to_f)
      timed_out = false
      @pending_mx.synchronize do
        if @pending[call_id].equal?(slot)
          @pending.delete(call_id)
          timed_out = true
        end
      end
      return unless timed_out

      invoke_async_block_safe(slot, EvalResult.failure(TimeoutError.new(
        format('no RET for %<id>s (timeout=%<timeout>.3fs)', id: call_id, timeout: timeout.to_f)
      )))
    end

    def append_r_stderr(text)
      @r_stderr_mx.synchronize do
        @r_stderr << text.to_s
        if @r_stderr.bytesize > @r_stderr_limit
          @r_stderr = @r_stderr.byteslice(-@r_stderr_limit, @r_stderr_limit) || +''
        end
      end
    end

    def current_r_stderr
      @r_stderr_mx.synchronize { @r_stderr.to_s.dup.strip }
    end
  end
end
