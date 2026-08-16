# frozen_string_literal: true

require 'stringio'
require 'galaaz'
require_relative '../lib/new_bridge/r_instance_manager'

module NewBridge
  class StubSessionClient
    attr_reader :source_path, :host, :bridge_host, :r_cmd, :runtime_source_path, :start_calls
    attr_accessor :eval_proc, :stopped

    @@instances = []
    @@start_errors = []

    def self.instances
      @@instances
    end

    def self.reset!
      @@instances = []
      @@start_errors = []
    end

    def self.enqueue_start_error(error)
      @@start_errors << error
    end

    def initialize(source_path:, host:, r_cmd:, runtime_source_path: nil, bridge_host: nil)
      @source_path = source_path
      @host = host
      @bridge_host = bridge_host
      @r_cmd = r_cmd
      @runtime_source_path = runtime_source_path
      @start_calls = []
      @stopped = false
      @eval_proc = ->(_code, _kwargs) { 'ok' }
      @@instances << self
    end

    def start(accept_timeout: nil)
      @start_calls << accept_timeout
      raise @@start_errors.shift unless @@start_errors.empty?
      true
    end

    def stop
      @stopped = true
    end

    def eval_r(code = nil, **kwargs)
      @eval_proc.call(code, kwargs)
    end
  end
end

describe NewBridge::RInstanceManager do
  let(:out) { StringIO.new }
  let(:mgr) do
    described_class.new(
      source_path: File.expand_path('../ext/new_bridge/gatekeeper.cpp', __dir__),
      session_client_class: NewBridge::StubSessionClient,
      out: out,
      docker_access_checker: -> { [true, nil] }
    )
  end

  before do
    NewBridge::StubSessionClient.reset!
  end

  it 'spawns local instances and tracks metadata/default' do
    mgr.spawn_local(instance_id: 'a', r_cmd: 'R', version: 'v1')
    mgr.spawn_local(instance_id: 'b', r_cmd: '/usr/bin/R', version: 'v2')

    expect(mgr.default_instance_id).to eq('a')
    ids = mgr.instance_ids
    expect(ids).to include('a', 'b')

    info = mgr.instances
    expect(info.size).to eq(2)
    expect(info.find { |h| h[:id] == 'a' }[:default]).to eq(true)
    expect(info.find { |h| h[:id] == 'b' }[:runtime]).to eq('local')
  end

  it 'raises on duplicate local instance id' do
    mgr.spawn_local(instance_id: 'a', version: 'v1')
    expect { mgr.spawn_local(instance_id: 'a', version: 'v1') }.to raise_error(ArgumentError, /already exists/)
  end

  it 'supports spawn runtime dispatch and container metadata' do
    mgr.spawn(instance_id: 'c1', runtime: 'container', version: 'v-current', image: 'r-image', bridge_hosts: ['host.docker.internal'])

    item = mgr.instances.find { |h| h[:id] == 'c1' }
    expect(item[:runtime]).to eq('container')
    expect(item[:provider]).to eq('docker')
    expect(item[:image]).to eq('r-image')
    expect(item[:container_name]).to include('galaaz-c1')
  end

  it 'supports local runtime via unified spawn API' do
    mgr.spawn(instance_id: 'l1', runtime: 'local', version: 'v-local', r_cmd: 'R')
    expect(mgr.instance_ids).to include('l1')
  end

  it 'rejects invalid runtime values and missing container image' do
    expect do
      mgr.spawn(instance_id: 'x', runtime: 'unknown', version: 'v')
    end.to raise_error(ArgumentError, /unsupported runtime/)

    expect do
      mgr.spawn(instance_id: 'x', runtime: 'container', version: 'v', image: '')
    end.to raise_error(ArgumentError, /image is required/)
  end

  it 'retries once on infrastructure timeout by restarting instance' do
    mgr.spawn_local(instance_id: 'a', version: 'v1')
    first = NewBridge::StubSessionClient.instances.first
    first.eval_proc = ->(_code, _kwargs) { raise Timeout::Error, 'timeout' }

    result = mgr.eval_r('1+1', session_id: 's1', instance_id: 'a')
    expect(result).to eq('ok')
    expect(NewBridge::StubSessionClient.instances.size).to eq(2)
    expect(first.stopped).to eq(true)
  end

  it 'routes by version and evaluates once per version' do
    mgr.spawn_local(instance_id: 'a', version: 'v1')
    mgr.spawn_local(instance_id: 'b', version: 'v1')
    mgr.spawn_local(instance_id: 'c', version: 'v2')

    expect(mgr.eval_with_version('2+2', version: 'v2')).to eq('ok')
    expect { mgr.eval_with_version('2+2', version: 'missing') }.to raise_error(KeyError)

    out = mgr.eval_all_versions('2+2')
    expect(out.keys.sort).to eq(%w[v1 v2])
  end

  it 'supports default switching and stop variants' do
    mgr.spawn_local(instance_id: 'a', version: 'v1')
    mgr.spawn_local(instance_id: 'b', version: 'v2')
    mgr.set_default_instance('b')
    expect(mgr.default_instance_id).to eq('b')
    expect { mgr.set_default_instance('missing') }.to raise_error(KeyError)

    mgr.stop_all(keep_default: true)
    expect(mgr.instance_ids).to eq(['b'])

    mgr.stop('b')
    expect(mgr.instance_ids).to eq([])
    expect(mgr.default_instance_id).to eq(nil)
  end

  it 'supports force killing container instances' do
    mgr.spawn(instance_id: 'c1', runtime: 'container', version: 'v-current', image: 'r-image', bridge_hosts: ['host.docker.internal'])
    expect { mgr.kill_container('c1') }.not_to raise_error

    mgr.spawn_local(instance_id: 'a', version: 'v1')
    expect { mgr.kill_container('a') }.to raise_error(ArgumentError, /not container runtime/)
  end

  it 'fails container spawn when docker checker reports inaccessible daemon' do
    bad_mgr = described_class.new(
      source_path: File.expand_path('../ext/new_bridge/gatekeeper.cpp', __dir__),
      session_client_class: NewBridge::StubSessionClient,
      out: out,
      docker_access_checker: -> { [false, 'permission denied'] }
    )

    expect do
      bad_mgr.spawn(instance_id: 'c2', runtime: 'container', version: 'v', image: 'img')
    end.to raise_error(NewBridge::RInstanceManager::Error, /docker daemon is not accessible: permission denied/)
  end

  it 'tries multiple bridge hosts and logs failures before succeeding' do
    NewBridge::StubSessionClient.enqueue_start_error(StandardError.new('accept failed'))
    mgr.spawn(
      instance_id: 'c-fallback',
      runtime: 'container',
      version: 'v',
      image: 'img',
      bridge_hosts: %w[bad.host good.host]
    )

    text = out.string
    expect(text).to include('trying bridge host bad.host')
    expect(text).to include('trying bridge host good.host')
    expect(text).to include('bridge host bad.host failed')
  end

  it 'raises when all bridge host candidates fail' do
    NewBridge::StubSessionClient.enqueue_start_error(StandardError.new('fail 1'))
    NewBridge::StubSessionClient.enqueue_start_error(StandardError.new('fail 2'))

    expect do
      mgr.spawn(
        instance_id: 'c-fail',
        runtime: 'container',
        version: 'v',
        image: 'img',
        bridge_hosts: %w[h1 h2]
      )
    end.to raise_error(NewBridge::RInstanceManager::Error, /container runtime start failed/)
  end

  it 'classifies retryable infrastructure errors conservatively' do
    expect(mgr.send(:infrastructure_retryable_error?, Timeout::Error.new('t'))).to eq(true)
    expect(mgr.send(:infrastructure_retryable_error?, IOError.new('io'))).to eq(true)
    expect(mgr.send(:infrastructure_retryable_error?, NewBridge::SessionClient::TimeoutError.new('timeout'))).to eq(true)
    expect(mgr.send(:infrastructure_retryable_error?, NewBridge::SessionClient::RProcessError.new('connection closed by peer'))).to eq(true)
    expect(mgr.send(:infrastructure_retryable_error?, NewBridge::SessionClient::RProcessError.new('evaluation error: bad call'))).to eq(false)
    expect(mgr.send(:infrastructure_retryable_error?, StandardError.new('other'))).to eq(false)
  end

  it 'builds bridge host candidates honoring preferred host cache' do
    mgr.instance_variable_set(:@preferred_bridge_host, 'cached.host')
    allow(mgr).to receive(:running_in_wsl?).and_return(false)
    allow(mgr).to receive(:local_wsl_ip).and_return('172.22.0.5')

    with_cache = mgr.send(:bridge_host_candidates, relearn: false)
    relearn = mgr.send(:bridge_host_candidates, relearn: true)

    expect(with_cache.first).to eq('cached.host')
    expect(with_cache).to include('host.docker.internal', '172.22.0.5')
    expect(relearn).to eq(%w[host.docker.internal 172.22.0.5])
  end

  it 'prefers WSL IP before host.docker.internal when running in WSL' do
    allow(mgr).to receive(:running_in_wsl?).and_return(true)
    allow(mgr).to receive(:local_wsl_ip).and_return('172.22.0.5')

    expect(mgr.send(:bridge_host_candidates, relearn: true)).to eq(%w[172.22.0.5 host.docker.internal])

    mgr.instance_variable_set(:@preferred_bridge_host, 'cached.host')
    with_cache = mgr.send(:bridge_host_candidates, relearn: false)
    expect(with_cache.first).to eq('cached.host')
    expect(with_cache).to eq(%w[cached.host 172.22.0.5 host.docker.internal])
  end

  it 'handles docker log and cleanup helper branches' do
    allow(Open3).to receive(:capture3).with('docker', 'logs', '--tail', '80', 'cname').and_return(['ok logs', '', instance_double(Process::Status, success?: true)])
    expect(mgr.send(:docker_logs, 'cname')).to eq('ok logs')

    allow(Open3).to receive(:capture3).with('docker', 'logs', '--tail', '80', 'cname2').and_return(['', 'no logs', instance_double(Process::Status, success?: false)])
    expect(mgr.send(:docker_logs, 'cname2')).to eq('no logs')

    allow(Open3).to receive(:capture3).with('docker', 'rm', '-f', 'dead-c').and_return(['', '', instance_double(Process::Status, success?: true)])
    expect { mgr.send(:cleanup_container, { runtime: 'container', container_name: 'dead-c' }, force: true) }.not_to raise_error
    expect { mgr.send(:cleanup_container, { runtime: 'container', container_name: '' }, force: true) }.not_to raise_error
    expect { mgr.send(:cleanup_container, { runtime: 'local' }, force: true) }.not_to raise_error
  end

  it 'reads local wsl ip and handles shell failures' do
    allow(Open3).to receive(:capture3).with('bash', '-lc', "hostname -I | awk '{print $1}'").and_return(["172.22.0.7\n", '', instance_double(Process::Status, success?: true)])
    expect(mgr.send(:local_wsl_ip)).to eq('172.22.0.7')

    allow(Open3).to receive(:capture3).with('bash', '-lc', "hostname -I | awk '{print $1}'").and_return(['', 'err', instance_double(Process::Status, success?: false)])
    expect(mgr.send(:local_wsl_ip)).to eq(nil)
  end

  it 'checks docker daemon access when checker is not provided' do
    mgr2 = described_class.new(
      source_path: File.expand_path('../ext/new_bridge/gatekeeper.cpp', __dir__),
      session_client_class: NewBridge::StubSessionClient,
      out: out
    )

    allow(Open3).to receive(:capture3).with('docker', 'info').and_return(['ok', '', instance_double(Process::Status, success?: true)])
    expect { mgr2.send(:ensure_docker_daemon_access!) }.not_to raise_error

    allow(Open3).to receive(:capture3).with('docker', 'info').and_return(['', 'permission denied', instance_double(Process::Status, success?: false)])
    expect { mgr2.send(:ensure_docker_daemon_access!) }.to raise_error(NewBridge::RInstanceManager::Error, /docker daemon is not accessible: permission denied/)
  end

  it 'handles helper rescues for docker logs, cleanup, and local ip' do
    allow(Open3).to receive(:capture3).with('docker', 'logs', '--tail', '80', 'boom').and_raise(StandardError, 'x')
    expect(mgr.send(:docker_logs, 'boom')).to eq('')

    allow(Open3).to receive(:capture3).with('docker', 'rm', '-f', 'boom').and_raise(StandardError, 'x')
    expect { mgr.send(:cleanup_container, { runtime: 'container', container_name: 'boom' }, force: true) }.not_to raise_error

    allow(Open3).to receive(:capture3).with('bash', '-lc', "hostname -I | awk '{print $1}'").and_raise(StandardError, 'x')
    expect(mgr.send(:local_wsl_ip)).to eq(nil)
  end
end

