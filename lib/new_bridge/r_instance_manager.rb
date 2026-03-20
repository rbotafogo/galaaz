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
      @meta = {}    # instance_id => { provider:, version:, r_cmd:, status: }
    end

    # Spawn a new local R gatekeeper process.
    #
    # @param instance_id [String]
    # @param r_cmd [String] R executable (or full path to it)
    # @param version [String, nil] semantic/version label for routing (e.g., "4.3.3")
    # @return [SessionClient]
    def spawn_local(instance_id:, r_cmd: @default_r_cmd, version: nil)
      raise ArgumentError, "instance already exists: #{instance_id}" if @clients.key?(instance_id)

      c = SessionClient.new(source_path: @source_path, host: @host, r_cmd: r_cmd)
      c.start
      @clients[instance_id] = c
      @meta[instance_id] = {
        provider: 'local',
        version: version,
        r_cmd: r_cmd,
        status: :healthy
      }
      c
    end

    def instance_ids
      @clients.keys
    end

    # Lightweight metadata view suitable for management UIs and tests.
    # Example:
    # [{ id: "a", provider: "local", version: "4.3.3", status: :healthy, r_cmd: "R" }]
    def instances
      @clients.keys.map do |id|
        m = @meta.fetch(id, {})
        {
          id: id,
          provider: m[:provider] || 'local',
          version: m[:version],
          status: m[:status] || :healthy,
          r_cmd: m[:r_cmd]
        }
      end
    end

    def eval_r(code, session_id:, instance_id:, parent_id: nil, timeout: 60)
      c = @clients.fetch(instance_id)
      c.eval_r(code, session_id: session_id, instance_id: instance_id, parent_id: parent_id, timeout: timeout)
    end

    # Route to an instance by version label.
    # If multiple instances share a version, first match is used (deterministic by insertion order).
    def eval_with_version(code, version:, session_id: 'default', timeout: 60)
      entry = @meta.find { |_id, m| m[:version] == version }
      raise KeyError, "no instance for version=#{version}" unless entry

      instance_id, = entry
      eval_r(code, session_id: session_id, instance_id: instance_id, timeout: timeout)
    end

    # Run the same code once per distinct version.
    # Returns a map keyed by version label.
    def eval_all_versions(code, session_id: 'default', timeout: 60)
      by_version = {}
      @meta.each do |id, m|
        v = m[:version]
        next if v.nil? || by_version.key?(v)

        by_version[v] = eval_r(code, session_id: session_id, instance_id: id, timeout: timeout)
      end
      by_version
    end

    def stop(instance_id = nil)
      if instance_id
        c = @clients.delete(instance_id)
        c&.stop
        @meta.delete(instance_id)
        return self
      end

      @clients.each_value(&:stop)
      @clients.clear
      @meta.clear
      self
    end

    def stop_all
      stop
    end
  end
end

