# frozen_string_literal: true

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 4.4 (Runtime interface local/container)' do
  class FakeSessionClient
    class << self
      attr_accessor :last_kwargs
    end

    attr_reader :kwargs

    def initialize(**kwargs)
      @kwargs = kwargs
      self.class.last_kwargs = kwargs
      @started = false
    end

    def start(*_args)
      @started = true
      self
    end

    def stop
      @started = false
    end

    def eval_r(code, session_id:, instance_id:, parent_id: nil, timeout: 60)
      {
        'kind' => 'integer',
        'value' => code.length + session_id.length + instance_id.length + timeout.to_i + (parent_id ? 1 : 0)
      }
    end
  end

  class BridgeLearningSessionClient < FakeSessionClient
    class << self
      attr_accessor :attempts
    end

    def start(*_args)
      self.class.attempts ||= []
      self.class.attempts << kwargs[:bridge_host]
      raise NewBridge::SessionClient::RProcessError, 'connect failed' if kwargs[:bridge_host] == 'bad-host'

      super
    end
  end

  class FlakyOnceSessionClient < FakeSessionClient
    class << self
      attr_accessor :calls, :instances
    end

    def initialize(**kwargs)
      super
      self.class.instances ||= 0
      self.class.instances += 1
      @instance_number = self.class.instances
    end

    def eval_r(code, session_id:, instance_id:, parent_id: nil, timeout: 60)
      self.class.calls ||= 0
      self.class.calls += 1
      if @instance_number == 1 && self.class.calls == 1
        raise NewBridge::SessionClient::RProcessError, 'R connection closed'
      end

      super
    end
  end

  class EvalErrorSessionClient < FakeSessionClient
    class << self
      attr_accessor :instances
    end

    def initialize(**kwargs)
      super
      self.class.instances ||= 0
      self.class.instances += 1
    end

    def eval_r(_code, session_id:, instance_id:, parent_id: nil, timeout: 60)
      raise NewBridge::SessionClient::RProcessError, 'evaluation error'
    end
  end

  let(:phase1_cpp) { File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__) }

  it 'spawns local runtime through unified spawn API' do
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FakeSessionClient,
      docker_access_checker: -> { [true, nil] }
    )

    mgr.spawn(instance_id: 'loc-a', runtime: 'local', version: '4.3.3')
    inst = mgr.instances.find { |h| h[:id] == 'loc-a' }

    expect(inst[:runtime]).to eq('local')
    expect(inst[:provider]).to eq('local')
    expect(inst[:version]).to eq('4.3.3')
    expect(inst[:default]).to eq(true)
  end

  it 'spawns container runtime through unified spawn API with versioned image' do
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FakeSessionClient,
      docker_access_checker: -> { [true, nil] }
    )

    mgr.spawn(
      instance_id: 'ctr-a',
      runtime: 'container',
      version: '3.6.3',
      image: 'galaaz/r:3.6.3'
    )

    inst = mgr.instances.find { |h| h[:id] == 'ctr-a' }
    expect(inst[:runtime]).to eq('container')
    expect(inst[:provider]).to eq('docker')
    expect(inst[:version]).to eq('3.6.3')
    expect(inst[:image]).to eq('galaaz/r:3.6.3')
    expect(FakeSessionClient.last_kwargs[:runtime_source_path]).to eq('/workspace/ext/new_bridge/galaaz_gatekeeper_phase1.cpp')
  end

  it 'routes by version across local and container instances' do
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FakeSessionClient,
      docker_access_checker: -> { [true, nil] }
    )

    mgr.spawn(instance_id: 'loc-a', runtime: 'local', version: '4.3.3')
    mgr.spawn(instance_id: 'ctr-a', runtime: 'container', version: '3.6.3', image: 'galaaz/r:3.6.3')

    out1 = mgr.eval_with_version('1L+1L', version: '4.3.3', session_id: 's')
    out2 = mgr.eval_with_version('1L+1L', version: '3.6.3', session_id: 's')

    expect(out1['kind']).to eq('integer')
    expect(out2['kind']).to eq('integer')
  end

  it 'keeps default instance running when stop_all(keep_default: true)' do
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FakeSessionClient,
      docker_access_checker: -> { [true, nil] }
    )
    mgr.spawn(instance_id: 'loc-a', runtime: 'local', version: '4.3.3')
    mgr.spawn(instance_id: 'ctr-a', runtime: 'container', version: '3.6.3', image: 'galaaz/r:3.6.3')
    mgr.set_default_instance('loc-a')

    mgr.stop_all(keep_default: true)
    ids = mgr.instance_ids
    expect(ids).to eq(['loc-a'])
    expect(mgr.default_instance_id).to eq('loc-a')
  end

  it 'raises if kill_container is called on local runtime' do
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FakeSessionClient,
      docker_access_checker: -> { [true, nil] }
    )
    mgr.spawn(instance_id: 'loc-a', runtime: 'local', version: '4.3.3')

    expect do
      mgr.kill_container('loc-a')
    end.to raise_error(ArgumentError, /not container runtime/)
  end

  it 'requires image when runtime is container' do
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FakeSessionClient,
      docker_access_checker: -> { [true, nil] }
    )

    expect do
      mgr.spawn(instance_id: 'ctr-a', runtime: 'container', version: '3.6.3')
    end.to raise_error(ArgumentError, /image is required/)
  end

  it 'learns successful bridge host after fallback and reuses it first next time' do
    BridgeLearningSessionClient.attempts = []
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: BridgeLearningSessionClient,
      docker_access_checker: -> { [true, nil] }
    )

    mgr.spawn(
      instance_id: 'ctr-a',
      runtime: 'container',
      version: '4.3.3',
      image: 'galaaz/r:4.3.3',
      bridge_hosts: %w[bad-host good-host]
    )
    expect(mgr.preferred_bridge_host).to eq('good-host')
    expect(BridgeLearningSessionClient.attempts).to eq(%w[bad-host good-host])

    mgr.stop_all(force_container: true)
    BridgeLearningSessionClient.attempts = []

    # Next spawn should try learned host first (from cache).
    mgr.spawn(
      instance_id: 'ctr-b',
      runtime: 'container',
      version: '4.3.3',
      image: 'galaaz/r:4.3.3',
      bridge_hosts: [mgr.preferred_bridge_host, 'bad-host']
    )
    expect(BridgeLearningSessionClient.attempts.first).to eq('good-host')
  end

  it 'supports explicit relearn to ignore cached preferred host order' do
    BridgeLearningSessionClient.attempts = []
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: BridgeLearningSessionClient,
      docker_access_checker: -> { [true, nil] }
    )
    mgr.instance_variable_set(:@preferred_bridge_host, 'stale-host')

    mgr.spawn(
      instance_id: 'ctr-a',
      runtime: 'container',
      version: '4.3.3',
      image: 'galaaz/r:4.3.3',
      bridge_hosts: %w[good-host stale-host],
      relearn_bridge_host: true
    )
    expect(BridgeLearningSessionClient.attempts.first).to eq('good-host')
  end

  it 'restarts and retries once on infrastructure/runtime failure' do
    FlakyOnceSessionClient.calls = 0
    FlakyOnceSessionClient.instances = 0
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: FlakyOnceSessionClient,
      docker_access_checker: -> { [true, nil] }
    )
    mgr.spawn(instance_id: 'loc-a', runtime: 'local', version: '4.3.3')

    out = mgr.eval_r('1L+1L', session_id: 's', instance_id: 'loc-a')
    expect(out['kind']).to eq('integer')
    expect(FlakyOnceSessionClient.instances).to eq(2)
  end

  it 'does not retry on evaluation errors' do
    EvalErrorSessionClient.instances = 0
    mgr = NewBridge::RInstanceManager.new(
      source_path: phase1_cpp,
      session_client_class: EvalErrorSessionClient,
      docker_access_checker: -> { [true, nil] }
    )
    mgr.spawn(instance_id: 'loc-a', runtime: 'local', version: '4.3.3')

    expect do
      mgr.eval_r('stop("boom")', session_id: 's', instance_id: 'loc-a')
    end.to raise_error(NewBridge::SessionClient::RProcessError, /evaluation error/)
    expect(EvalErrorSessionClient.instances).to eq(1)
  end
end

