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
    @mgr.spawn_local(instance_id: 'mgr-a')
    @mgr.spawn_local(instance_id: 'mgr-b')
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
end

