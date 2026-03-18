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

    def initialize(cpp_path:, host: '127.0.0.1', r_cmd: 'R')
      @cpp_path = File.expand_path(cpp_path)
      @host = host
      @r_cmd = r_cmd
      @server = nil
      @sock = nil
      @write_mx = Mutex.new
      @pending = {}
      @pending_mx = Mutex.new
      @reader = nil
      @r_stderr = +''
      @r_exit_status = nil
    end

    def start(accept_timeout: 120)
      @server = TCPServer.new(@host, 0)
      port = @server.addr[1]
      cpp_escaped = @cpp_path.gsub("'", "\\\\'")
      r_script = <<~R
        host <- "#{@host}"
        port <- #{port}
        stopifnot(requireNamespace("Rcpp", quietly = TRUE))
        library(Rcpp)
        sourceCpp("#{cpp_escaped}")
        galaaz_run_bridge(host, as.integer(port))
      R

      env = { 'GALAAZ_BRIDGE_HOST' => @host, 'GALAAZ_BRIDGE_PORT' => port.to_s }
      @r_thr = Thread.new do
        _stdin, stdout_err, wait_thr = Open3.popen2e(env, @r_cmd, '--slave', '--no-save', '-e', r_script)
        @r_stderr = stdout_err.read
        @r_exit_status = wait_thr.value
      end

      @sock = Timeout.timeout(accept_timeout) { @server.accept }
      @reader = Thread.new { reader_loop }
      self
    end

    def stop
      @sock&.close rescue nil
      @server&.close rescue nil
      @reader&.join(3)
      @r_thr&.join(15)
    end

    def eval_r(code, session_id: 'default', timeout: 60)
      call_id = SecureRandom.uuid
      q = Queue.new
      @pending_mx.synchronize { @pending[call_id] = q }
      req = Envelope.encode(
        'call_id' => call_id,
        'type' => 'REQ',
        'session_id' => session_id,
        'payload' => code,
        'parent_id' => nil
      )
      @write_mx.synchronize { Framing.write_frame(@sock, req) }

      ret = wait_for_ret(q, call_id, timeout)
      status = ret['status']
      payload = ret['payload']
      parsed = JSON.parse(payload)
      raise RProcessError, parsed['message'] || payload unless status == 'success'

      parsed
    end

    private

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
        next unless h['type'] == 'RET'

        q = @pending_mx.synchronize { @pending.delete(h['call_id']) }
        q&.push(h)
      end
    rescue Framing::TruncatedFrame, Framing::Error, IOError, Errno::ECONNRESET, Errno::EPIPE, Envelope::Error
      signal_closed
    end

    def signal_closed
      @pending_mx.synchronize do
        @pending.each_value { |q| q.push(:closed) }
        @pending.clear
      end
    end
  end
end
