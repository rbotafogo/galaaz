# frozen_string_literal: true

# Phase 1: REQ/RET, per-session env, concurrency. Run: bundle exec rspec specs/new_bridge/phase1_req_ret_spec.rb

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 1 REQ/RET' do
  let(:phase1_cpp) { File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__) }

  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    cpp = File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)
    @client = NewBridge::SessionClient.new(source_path: cpp)
    @client.start
  end

  after(:all) do
    @client&.stop
  end

  def with_client
    yield @client
  end

  it 'evaluates 1+1 as integer 2' do
    with_client do |c|
      out = c.eval_r('1L + 1L')
      expect(out['kind']).to eq('integer')
      expect(out['value']).to eq(2)
    end
  end

  it 'returns double scalar' do
    with_client do |c|
      out = c.eval_r('1.5 + 1')
      expect(out['kind']).to eq('double')
      expect(out['value']).to be_within(1e-9).of(2.5)
    end
  end

  it 'isolates variables per session_id' do
    with_client do |c|
      c.eval_r('x <- 42L', session_id: 'sess-a')
      c.eval_r('x <- 99L', session_id: 'sess-b')
      expect(c.eval_r('x', session_id: 'sess-a')['value']).to eq(42)
      expect(c.eval_r('x', session_id: 'sess-b')['value']).to eq(99)
    end
  end

  it 'handles 10 concurrent Ruby threads with distinct sessions' do
    with_client do |c|
      threads = 10.times.map do |i|
        Thread.new do
          sid = "thr-#{i}"
          c.eval_r("y <- #{i}L", session_id: sid)
          c.eval_r('y', session_id: sid)['value']
        end
      end
      values = threads.map(&:value)
      expect(values.sort).to eq((0..9).to_a)
    end
  end
end
