# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'socket'
require 'timeout'

require_relative 'envelope'
require_relative 'framing'

module NewBridge
  # NewBridge::SessionClient
  #
  # Responsibilities (Ruby side, inside one Ruby process):
  # - Accept a single TCP connection from one R runtime process.
  # - Serialize and send framed MsgPack envelopes of type `REQ`.
  # - Wait for matching framed MsgPack envelopes of type `RET`.
  # - Handle R -> Ruby callback requests (`CALL`) by invoking registered Ruby
  #   blocks in background threads and replying with `RET`.
  #
  # Protocol basics
  # - Transport: TCP, length-prefixed framing handled by `NewBridge::Framing`.
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
  #   - `RET` -> pushes into the per-call Queue waiting on REQ
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
    # @param bridge_host [String,nil] host value injected into R script (defaults to `host`).
    # @param runtime_source_path [String,nil] source path visible from runtime process/container.
    # @param r_cmd [String, Array<String>] executable (or argv prefix ending with executable).
    def initialize(source_path:, host: '127.0.0.1', bridge_host: nil, runtime_source_path: nil, r_cmd: 'R')
      @source_path = File.expand_path(source_path)
      @use_precompiled = @source_path.end_with?('.so')
      @host = host
      @bridge_host = bridge_host || host
      @runtime_source_path = runtime_source_path || @source_path
      @r_cmd = r_cmd
      @server = nil
      @sock = nil
      @write_mx = Mutex.new
      @pending = {}
      @pending_mx = Mutex.new
      @callbacks = {}
      @callbacks_mx = Mutex.new
      @reader = nil
      @r_stderr = +''
      @r_exit_status = nil
    end

    # Start listening for a single TCP connection from one R process and launch that process.
    #
    # - Binds to an ephemeral port (server.addr[1]).
    # - Starts a thread that runs `r_cmd` and sources the gatekeeper C++ code inside R.
    # - Accepts the runtime connection with `accept_timeout`.
    #
    # On startup failure (e.g. runtime exits before connecting), it surfaces R stderr and exit status.
    def start(accept_timeout: 120)
      @server = TCPServer.new(@host, 0)
      port = @server.addr[1]

      # Use sourceCpp with a persistent cache directory so repeated runtime
      # starts can reuse compiled shared objects when source is unchanged.
      cpp_escaped = @runtime_source_path.gsub("'", "\\\\'")
      rcpp_cache_dir = (ENV['GALAAZ_RCPP_CACHE_DIR'] || File.join(Dir.tmpdir, 'galaaz_rcpp_cache')).gsub("'", "\\\\'")
      r_script = <<~R
        bridge_host <- "#{@bridge_host}"
        port <- #{port}
        stopifnot(requireNamespace("Rcpp", quietly = TRUE))
        library(Rcpp)
        dir.create("#{rcpp_cache_dir}", recursive = TRUE, showWarnings = FALSE)
        sourceCpp(file = "#{cpp_escaped}", rebuild = FALSE, cacheDir = "#{rcpp_cache_dir}")
        galaaz_run_bridge(bridge_host, as.integer(port))
      R

      env = { 'GALAAZ_BRIDGE_HOST' => @bridge_host, 'GALAAZ_BRIDGE_PORT' => port.to_s }
      @r_thr = Thread.new do
        launch = @r_cmd.is_a?(Array) ? @r_cmd.dup : [@r_cmd]
        _stdin, stdout_err, wait_thr = Open3.popen2e(env, *launch, '--slave', '--no-save', '-e', r_script)
        @r_stderr = stdout_err.read
        @r_exit_status = wait_thr.value
      end

      @sock = Timeout.timeout(accept_timeout) { @server.accept }
      @reader = Thread.new { reader_loop }
      self
    rescue Timeout::Error
      # If the runtime process failed early (e.g. docker permission/network/source path),
      # surface stderr/exit details instead of a generic accept timeout.
      process_status = @r_exit_status&.exitstatus
      details = @r_stderr.to_s.strip
      msg = "failed to accept runtime connection within #{accept_timeout}s"
      msg += " (runtime exit=#{process_status})" if process_status
      msg += " stderr=#{details[0, 600]}" unless details.empty?
      raise RProcessError, msg
    end

    # Stop the client and attempt to join threads cleanly.
    # Best-effort: socket/server are closed, reader thread is joined, runtime thread is joined.
    def stop
      @sock&.close rescue nil
      @server&.close rescue nil
      @reader&.join(3)
      @r_thr&.join(15)
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

    # Register a Ruby callback for R->Ruby `CALL` envelopes.
    #
    # The gatekeeper will invoke this callback when it receives a `CALL` with the
    # corresponding `callback_call_id`, and this client will reply with a `RET`.
    def register_callback(&block)
      callback_call_id = SecureRandom.uuid
      @callbacks_mx.synchronize { @callbacks[callback_call_id] = block }
      callback_call_id
    end

    private

    # Emit debug logs when GALAAZ_DEBUG is set.
    def debug_log(msg)
      return unless ENV['GALAAZ_DEBUG']
      STDERR.puts("[NewBridge::SessionClient] #{msg}")
      STDERR.flush
    end

    # Wait for RET for one `call_id` by popping from queue `q`.
    # On timeout it removes the pending queue and raises TimeoutError.
    def wait_for_ret(q, call_id, timeout)
      Timeout.timeout(timeout) do
        v = q.pop
        raise RProcessError, 'R connection closed' if v == :closed

        v
      end
    rescue Timeout::Error
      @pending_mx.synchronize { @pending.delete(call_id) }
      raise TimeoutError, "no RET for #{call_id}"
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
          q = @pending_mx.synchronize { @pending.delete(h['call_id']) }
          q&.push(h)
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

      callback = @callbacks_mx.synchronize { @callbacks.delete(call_id) }
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
          send_ret(call_id: call_id, status: 'success', payload: result.to_s, instance_id: instance_id)
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
      @pending_mx.synchronize do
        @pending.each_value { |q| q.push(:closed) }
        @pending.clear
      end
    end
  end
end
