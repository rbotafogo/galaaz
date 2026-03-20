# frozen_string_literal: true

require_relative 'session_client'

module NewBridge
  # Phase 4.3 (local): Manage a dynamic set of R instances.
  #
  # This is the first slice of the planned production-grade instance manager:
  # - spawn local R processes on demand
  # - evaluate code via the spawned SessionClient instances
  # - stop one or all instances
  #
  # Container provisioning and multi-version orchestration are deferred.
  class RInstanceManager
    class Error < StandardError; end

    def initialize(source_path:, host: '127.0.0.1', default_r_cmd: 'R')
      @source_path = File.expand_path(source_path)
      @host = host
      @default_r_cmd = default_r_cmd
      @clients = {} # instance_id => SessionClient
    end

    # Spawn a new local R gatekeeper process.
    #
    # @param instance_id [String]
    # @param r_cmd [String] R executable (or full path to it)
    # @return [SessionClient]
    def spawn_local(instance_id:, r_cmd: @default_r_cmd)
      raise ArgumentError, "instance already exists: #{instance_id}" if @clients.key?(instance_id)

      c = SessionClient.new(source_path: @source_path, host: @host, r_cmd: r_cmd)
      c.start
      @clients[instance_id] = c
      c
    end

    def instance_ids
      @clients.keys
    end

    def eval_r(code, session_id:, instance_id:, parent_id: nil, timeout: 60)
      c = @clients.fetch(instance_id)
      c.eval_r(code, session_id: session_id, instance_id: instance_id, parent_id: parent_id, timeout: timeout)
    end

    def stop(instance_id = nil)
      if instance_id
        c = @clients.delete(instance_id)
        c&.stop
        return self
      end

      @clients.each_value(&:stop)
      @clients.clear
      self
    end
  end
end

