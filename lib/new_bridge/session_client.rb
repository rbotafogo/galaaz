# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'socket'
require 'tmpdir'
require 'timeout'

require_relative 'envelope'
require_relative 'framing'

module NewBridge
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
      raise RProcessError, msg
    end

    # Stop the client and attempt to join threads cleanly.
    # Best-effort: socket/server are closed, reader thread is joined, runtime thread is joined.
    def stop
      @sock&.close rescue nil
      @server&.close rescue nil
      if @unix_path && File.socket?(@unix_path)
        File.unlink(@unix_path) rescue nil
      end
      @unix_path = nil
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
