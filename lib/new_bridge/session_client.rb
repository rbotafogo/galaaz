# frozen_string_literal: true

require 'json'
require 'open3'
require 'securerandom'
require 'socket'
require 'timeout'

require_relative 'envelope'
require_relative 'framing'

module NewBridge
  # Phase 1: one R process connects as TCP client; Ruby accepts and sends REQ / receives RET.
  class SessionClient
    class Error < StandardError; end
    class TimeoutError < Error; end
    class RProcessError < Error; end

    attr_reader :r_stderr, :r_exit_status

    # @param source_path [String] Host-side path to .cpp or .so
    # @param host [String] bind/listen address for Ruby TCP server
    # @param bridge_host [String,nil] host value injected into R script (defaults to host)
    # @param runtime_source_path [String,nil] source path visible from runtime process/container
    # @param r_cmd [String, Array<String>] executable (or argv prefix ending with executable)
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

    def start(accept_timeout: 120)
      @server = TCPServer.new(@host, 0)
      port = @server.addr[1]

      # Always use sourceCpp for now - dyn.load needs more work
      cpp_escaped = @runtime_source_path.gsub("'", "\\\\'")
      r_script = <<~R
        host <- "#{@bridge_host}"
        port <- #{port}
        stopifnot(requireNamespace("Rcpp", quietly = TRUE))
        library(Rcpp)
        sourceCpp("#{cpp_escaped}")
        galaaz_run_bridge(host, as.integer(port))
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

    def stop
      @sock&.close rescue nil
      @server&.close rescue nil
      @reader&.join(3)
      @r_thr&.join(15)
    end

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
      parsed = JSON.parse(payload)
      raise RProcessError, parsed['message'] || payload unless status == 'success'

      parsed
    end

    # Phase 3: register a Ruby callback for R->Ruby CALL envelopes.
    # The R side will call back with the returned `callback_call_id`.
    def register_callback(&block)
      callback_call_id = SecureRandom.uuid
      @callbacks_mx.synchronize { @callbacks[callback_call_id] = block }
      callback_call_id
    end

    private

    def debug_log(msg)
      return unless ENV['GALAAZ_DEBUG']
      STDERR.puts("[NewBridge::SessionClient] #{msg}")
      STDERR.flush
    end

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

    def signal_closed
      @pending_mx.synchronize do
        @pending.each_value { |q| q.push(:closed) }
        @pending.clear
      end
    end
  end
end
