# frozen_string_literal: true

require_relative 'session_client'

module NewBridge
  # Phase 2: manage a small pool of external R gatekeeper processes.
  # Each instance is isolated by having its own TCP socket + R process.
  class InstancePoolClient
    class Error < StandardError; end

    # @param source_path [String] Path to either .cpp file (uses sourceCpp) or .so file (uses dyn.load)
    def initialize(source_path:, instances:, host: '127.0.0.1', r_cmd: 'R')
      @instances = instances
      @host = host
      @r_cmd = r_cmd
      @clients = {}
      instances.each do |instance_id|
        @clients[instance_id] = SessionClient.new(source_path: source_path, host: @host, r_cmd: @r_cmd)
      end
    end

    def start
      @instances.each { |iid| @clients.fetch(iid).start }
      self
    end

    def stop
      @clients.each_value(&:stop)
      self
    end

    def eval_r(code, session_id:, instance_id:, timeout: 60)
      client = @clients.fetch(instance_id)
      client.eval_r(code, session_id: session_id, instance_id: instance_id, timeout: timeout)
    end
  end
end

