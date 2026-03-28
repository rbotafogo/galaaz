# frozen_string_literal: true

# Phase 2: multi-instance correctness and isolation.
# Run: bundle exec rspec specs/new_bridge/phase2_multi_instance_spec.rb

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 2 (REQ/RET Multi-instance)' do
  before(:all) do
    cpp_path = File.expand_path('../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)
    @pool = NewBridge::InstancePoolClient.new(
      source_path: cpp_path,
      instances: ['instance-a', 'instance-b']
    ).start
  end

  after(:all) do
    @pool&.stop
  end

  it 'multi-instance correctness: same session_id on different instances stays isolated' do
    @pool.eval_r('x <- 11L', session_id: 'shared-session', instance_id: 'instance-a')
    @pool.eval_r('x <- 22L', session_id: 'shared-session', instance_id: 'instance-b')

    a_val = @pool.eval_r('x', session_id: 'shared-session', instance_id: 'instance-a')
    b_val = @pool.eval_r('x', session_id: 'shared-session', instance_id: 'instance-b')

    expect(a_val['value']).to eq(11)
    expect(b_val['value']).to eq(22)
  end

  it 'instance isolation under concurrency with distinct session_ids' do
    threads = 20.times.map do |i|
      Thread.new do
        sid = "sess-#{i}"
        inst = (i.even? ? 'instance-a' : 'instance-b')
        @pool.eval_r("y <- #{i}L; y", session_id: sid, instance_id: inst)['value']
      end
    end

    values = threads.map(&:value)
    expect(values.sort).to eq((0..19).to_a)
  end

  it 'stress (light): many REQ calls across the pool' do
    count = 100
    threads = 10.times.map do |t|
      Thread.new do
        start_i = t * (count / 10)
        end_i = start_i + (count / 10) - 1
        inst = (t.even? ? 'instance-a' : 'instance-b')

        (start_i..end_i).map do |i|
          sid = "stress-sess-#{t}-#{i}"
          @pool.eval_r("z <- #{i}L; z", session_id: sid, instance_id: inst)['value']
        end
      end
    end

    values = threads.flat_map(&:value)
    expect(values.sort).to eq((0..(count - 1)).to_a)
  end
end

