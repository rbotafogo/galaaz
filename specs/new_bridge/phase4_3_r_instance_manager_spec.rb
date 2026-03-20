# frozen_string_literal: true

# Phase 4.3: local R instance management API (first slice).
# Run: bundle exec rspec specs/new_bridge/phase4_3_r_instance_manager_spec.rb

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 4.3 (RInstanceManager - local)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    phase1_cpp = File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)
    @mgr = NewBridge::RInstanceManager.new(source_path: phase1_cpp)
    @mgr.spawn_local(instance_id: 'mgr-a', version: 'v-current')
    @mgr.spawn_local(instance_id: 'mgr-b', version: 'v-legacy')
  end

  after(:all) do
    @mgr&.stop
  end

  it 'evaluates code in isolated instances with routing by instance_id' do
    @mgr.eval_r('x <- 11L', session_id: 'shared-sid', instance_id: 'mgr-a')
    @mgr.eval_r('x <- 22L', session_id: 'shared-sid', instance_id: 'mgr-b')

    a = @mgr.eval_r('x', session_id: 'shared-sid', instance_id: 'mgr-a')
    b = @mgr.eval_r('x', session_id: 'shared-sid', instance_id: 'mgr-b')

    expect(a['value']).to eq(11)
    expect(b['value']).to eq(22)
  end

  it 'raises on spawning an existing instance_id' do
    expect do
      @mgr.spawn_local(instance_id: 'mgr-a')
    end.to raise_error(ArgumentError, /instance already exists/)
  end

  it 'exposes instance metadata including version labels' do
    list = @mgr.instances
    ids = list.map { |h| h[:id] }
    expect(ids).to include('mgr-a', 'mgr-b')

    a = list.find { |h| h[:id] == 'mgr-a' }
    b = list.find { |h| h[:id] == 'mgr-b' }
    expect(a[:version]).to eq('v-current')
    expect(b[:version]).to eq('v-legacy')
    expect(a[:status]).to eq(:healthy)
    expect(b[:provider]).to eq('local')
  end

  it 'routes eval by version with eval_with_version' do
    out = @mgr.eval_with_version('10L + 5L', version: 'v-current', session_id: 'ver-sess')
    expect(out['value']).to eq(15)
  end

  it 'returns one result per version with eval_all_versions' do
    results = @mgr.eval_all_versions('3L + 4L', session_id: 'all-vers')
    expect(results.keys.sort).to eq(%w[v-current v-legacy])
    expect(results['v-current']['value']).to eq(7)
    expect(results['v-legacy']['value']).to eq(7)
  end

  it 'stops instances on demand' do
    @mgr.stop('mgr-a')
    expect(@mgr.instance_ids).not_to include('mgr-a')

    expect do
      @mgr.eval_r('1L + 1L', session_id: 's', instance_id: 'mgr-a')
    end.to raise_error(KeyError)

    # remaining instance still works
    out = @mgr.eval_r('2L + 2L', session_id: 's', instance_id: 'mgr-b')
    expect(out['value']).to eq(4)
  end

  it 'raises when eval_with_version targets unknown version' do
    expect do
      @mgr.eval_with_version('1L + 1L', version: 'no-such-version')
    end.to raise_error(KeyError, /no instance for version/)
  end
end

