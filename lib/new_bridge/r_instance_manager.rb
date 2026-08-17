# frozen_string_literal: true

require 'open3'
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

    attr_reader :default_instance_id, :preferred_bridge_host

    def initialize(source_path:, host: '127.0.0.1', default_r_cmd: 'R', session_client_class: SessionClient, out: $stdout, docker_access_checker: nil)
      @source_path = File.expand_path(source_path)
      @host = host
      @default_r_cmd = default_r_cmd
      @session_client_class = session_client_class
      @out = out
      @docker_access_checker = docker_access_checker
      @clients = {} # instance_id => SessionClient
      @meta = {}    # instance_id => { provider:, runtime:, version:, r_cmd:, status:, image: }
      @default_instance_id = nil
      @preferred_bridge_host = nil
    end

    # Spawn a new local R gatekeeper process.
    #
    # @param instance_id [String]
    # @param r_cmd [String] R executable (or full path to it)
    # @param version [String, nil] semantic/version label for routing (e.g., "4.3.3")
    # @return [SessionClient]
    def spawn_local(instance_id:, r_cmd: @default_r_cmd, version: nil)
      raise ArgumentError, "instance already exists: #{instance_id}" if @clients.key?(instance_id)

      @out.puts("[RInstanceManager] starting local instance #{instance_id} version=#{version || 'n/a'}")
      c = @session_client_class.new(source_path: @source_path, host: @host, r_cmd: r_cmd)
      c.start
      @clients[instance_id] = c
      @meta[instance_id] = {
        provider: 'local',
        runtime: 'local',
        version: version,
        r_cmd: r_cmd,
        status: :healthy
      }
      @default_instance_id ||= instance_id
      c
    end

    # Spawn R in a container image.
    #
    # Notes:
    # - This uses Docker and assumes the image can execute `R` with Rcpp available.
    # - We mount the project root into /workspace and source the gatekeeper from that path.
    def spawn_container(instance_id:, image:, version:, container_name: nil, r_exec: 'R', accept_timeout: 30,
      bridge_host: nil, bridge_hosts: nil, relearn_bridge_host: false)
      raise ArgumentError, "instance already exists: #{instance_id}" if @clients.key?(instance_id)
      ensure_docker_daemon_access!

      source_dir = File.dirname(@source_path)
      project_root = File.expand_path('../..', source_dir)
      runtime_source = "/workspace/ext/new_bridge/#{File.basename(@source_path)}"
      base_name = container_name || "galaaz-#{instance_id}"
      host_candidates = if bridge_host
                          [bridge_host]
                        elsif bridge_hosts
                          bridge_hosts
                        else
                          bridge_host_candidates(relearn: relearn_bridge_host)
                        end
      @out.puts("[RInstanceManager] starting container instance #{instance_id} image=#{image} version=#{version}")
      @out.puts("[RInstanceManager] bridge host candidates: #{host_candidates.join(', ')}")

      c = nil
      last_error = nil
      selected_name = nil
      selected_host = nil
      selected_launch = nil

      host_candidates.each_with_index do |bridge_host, idx|
        name = "#{base_name}-#{idx}"
        @out.puts("[RInstanceManager] trying bridge host #{bridge_host} (attempt #{idx + 1}/#{host_candidates.size})")
        launch = [
          'docker', 'run',
          '--name', name,
          '--add-host', 'host.docker.internal:host-gateway',
          '-v', "#{project_root}:/workspace",
          image, r_exec
        ]

        c = @session_client_class.new(
          source_path: @source_path,
          runtime_source_path: runtime_source,
          host: '0.0.0.0',
          bridge_host: bridge_host,
          r_cmd: launch
        )
        begin
          c.start(accept_timeout: accept_timeout)
          selected_name = name
          selected_host = bridge_host
          selected_launch = launch
          @out.puts("[RInstanceManager] container instance #{instance_id} connected via #{bridge_host}")
          break
        rescue StandardError => e
          last_error = e
          logs = docker_logs(name, tail: 120)
          @out.puts("[RInstanceManager] bridge host #{bridge_host} failed: #{e.message}")
          if bridge_host == @preferred_bridge_host
            @out.puts("[RInstanceManager] cached bridge host failed, trying fallback candidates...")
          end
          @out.puts(logs) unless logs.nil? || logs.empty?
          docker_rm_force(name)
          c = nil
        end
      end

      if c.nil?
        raise Error, "container runtime start failed instance=#{instance_id} image=#{image}: #{last_error&.message}"
      end
      if selected_host && selected_host != @preferred_bridge_host
        @preferred_bridge_host = selected_host
        @out.puts("[RInstanceManager] learned preferred bridge host: #{@preferred_bridge_host}")
      end

      @clients[instance_id] = c
      @meta[instance_id] = {
        provider: 'docker',
        runtime: 'container',
        version: version,
        image: image,
        bridge_host: selected_host,
        container_name: selected_name,
        r_cmd: selected_launch,
        status: :healthy
      }
      @default_instance_id ||= instance_id
      c
    end

    # Unified spawn API.
    # runtime: 'local' or 'container'
    def spawn(instance_id:, runtime:, version:, r_cmd: @default_r_cmd, image: nil, container_name: nil, accept_timeout: 30,
      bridge_host: nil, bridge_hosts: nil, relearn_bridge_host: false)
      case runtime.to_s
      when 'local'
        spawn_local(instance_id: instance_id, r_cmd: r_cmd, version: version)
      when 'container'
        raise ArgumentError, 'image is required for container runtime' if image.nil? || image.empty?

        spawn_container(
          instance_id: instance_id,
          image: image,
          version: version,
          container_name: container_name,
          accept_timeout: accept_timeout,
          bridge_host: bridge_host,
          bridge_hosts: bridge_hosts,
          relearn_bridge_host: relearn_bridge_host
        )
      else
        raise ArgumentError, "unsupported runtime=#{runtime} (expected 'local' or 'container')"
      end
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
          runtime: m[:runtime] || 'local',
          version: m[:version],
          status: m[:status] || :healthy,
          r_cmd: m[:r_cmd],
          image: m[:image],
          container_name: m[:container_name],
          default: (id == @default_instance_id)
        }
      end
    end

    def eval_r(code, session_id:, instance_id:, parent_id: nil, timeout: 60)
      c = @clients.fetch(instance_id)
      c.eval_r(code, session_id: session_id, instance_id: instance_id, parent_id: parent_id, timeout: timeout)
    rescue StandardError => e
      raise unless infrastructure_retryable_error?(e)
      raise unless @clients.key?(instance_id)

      @out.puts("[RInstanceManager] runtime failure on instance=#{instance_id}: #{e.class}: #{e.message}")
      @out.puts("[RInstanceManager] attempting one restart+retry for instance=#{instance_id}")
      restart_instance(instance_id)
      c2 = @clients.fetch(instance_id)
      c2.eval_r(code, session_id: session_id, instance_id: instance_id, parent_id: parent_id, timeout: timeout)
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

    def set_default_instance(instance_id)
      raise KeyError, "unknown instance_id=#{instance_id}" unless @clients.key?(instance_id)

      @default_instance_id = instance_id
    end

    # Stop one instance or all instances.
    # - keep_default: when stopping all, leaves default instance alive.
    # - force_container: when stopping container instances, force-remove docker container.
    def stop(instance_id = nil, keep_default: false, force_container: false)
      if instance_id
        c = @clients.delete(instance_id)
        c&.stop
        m = @meta.delete(instance_id)
        cleanup_container(m, force: force_container)
        @default_instance_id = @clients.keys.first if @default_instance_id == instance_id
        return self
      end

      ids = @clients.keys
      ids.each do |id|
        next if keep_default && id == @default_instance_id

        c = @clients.delete(id)
        c&.stop
        m = @meta.delete(id)
        cleanup_container(m, force: force_container)
      end

      if @clients.empty?
        @default_instance_id = nil
      elsif @default_instance_id.nil? || !@clients.key?(@default_instance_id)
        @default_instance_id = @clients.keys.first
      end
      self
    end

    def stop_all(keep_default: false, force_container: false)
      stop(nil, keep_default: keep_default, force_container: force_container)
    end

    # Explicitly force-kill a container-backed runtime instance.
    # Useful when user wants to ensure no container stays alive after a versioned run.
    def kill_container(instance_id)
      m = @meta.fetch(instance_id)
      raise ArgumentError, "instance #{instance_id} is not container runtime" unless m[:runtime] == 'container'

      stop(instance_id, force_container: true)
    end

    private

    def restart_instance(instance_id)
      m = @meta.fetch(instance_id)
      stop(instance_id, force_container: true)
      case m[:runtime]
      when 'container'
        spawn_container(
          instance_id: instance_id,
          image: m[:image],
          version: m[:version],
          container_name: m[:container_name],
          accept_timeout: 30,
          bridge_host: m[:bridge_host]
        )
      else
        spawn_local(instance_id: instance_id, r_cmd: m[:r_cmd] || @default_r_cmd, version: m[:version])
      end
    end

    def infrastructure_retryable_error?(e)
      return true if e.is_a?(Timeout::Error)
      return true if e.is_a?(Errno::EPIPE) || e.is_a?(Errno::ECONNRESET) || e.is_a?(IOError)
      return true if e.is_a?(NewBridge::SessionClient::TimeoutError)
      return false unless e.is_a?(NewBridge::SessionClient::RProcessError)

      msg = e.message.to_s.downcase
      return false if msg.include?('evaluation error') || msg.include?('parse error')
      msg.include?('connection closed') || msg.include?('failed to accept runtime connection')
    end

    def cleanup_container(meta, force:)
      return unless meta && meta[:runtime] == 'container'
      return unless force

      name = meta[:container_name]
      docker_rm_force(name)
    end

    def docker_rm_force(name)
      return if name.nil? || name.empty?

      Open3.capture3('docker', 'rm', '-f', name)
    rescue StandardError
      nil
    end

    def docker_logs(container_name, tail: 80)
      out, err, st = Open3.capture3('docker', 'logs', '--tail', tail.to_s, container_name)
      return out if st.success?

      err.to_s
    rescue StandardError
      ''
    end

    # Hostnames/IPs the container should try when dialing back to JRuby.
    #
    # On WSL2 + Docker Desktop, +host.docker.internal+ / host-gateway points at the
    # Desktop VM, not the WSL distro where JRuby listens — so prefer the WSL eth0 IP
    # first. Elsewhere, prefer +host.docker.internal+ and keep the local IP as fallback.
    def bridge_host_candidates(relearn: false)
      wsl_ip = local_wsl_ip
      wsl_ip = nil if wsl_ip.nil? || wsl_ip.empty?

      cands = if running_in_wsl?
                [wsl_ip, 'host.docker.internal'].compact
              else
                ['host.docker.internal', wsl_ip].compact
              end

      if !relearn && @preferred_bridge_host
        ([@preferred_bridge_host] + cands).uniq
      else
        cands.uniq
      end
    end

    def running_in_wsl?
      return true unless ENV['WSL_DISTRO_NAME'].to_s.empty?
      return true unless ENV['WSL_INTEROP'].to_s.empty?

      ver = File.exist?('/proc/version') ? File.read('/proc/version') : ''
      !!(ver =~ /microsoft|wsl/i)
    rescue StandardError
      false
    end

    def local_wsl_ip
      out, _err, st = Open3.capture3('bash', '-lc', "hostname -I | awk '{print $1}'")
      return nil unless st.success?

      out.to_s.strip
    rescue StandardError
      nil
    end

    def ensure_docker_daemon_access!
      if @docker_access_checker
        ok, err = @docker_access_checker.call
        return if ok

        msg = +'docker daemon is not accessible'
        msg << ": #{err}" unless err.to_s.strip.empty?
        msg << '. Try: `newgrp docker` (or reopen WSL terminal) and verify `docker info`.'
        raise Error, msg
      end

      _out, err, st = Open3.capture3('docker', 'info')
      return if st.success?

      msg = +'docker daemon is not accessible'
      unless err.to_s.strip.empty?
        msg << ": #{err.to_s.strip}"
      end
      msg << '. Try: `newgrp docker` (or reopen WSL terminal) and verify `docker info`.'
      raise Error, msg
    end
  end
end

