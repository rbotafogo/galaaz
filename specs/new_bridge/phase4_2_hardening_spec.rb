# frozen_string_literal: true

# Phase 4.2: hardening coverage (edge cases + stress) on current bridge API.
# Run: bundle exec rspec specs/new_bridge/phase4_2_hardening_spec.rb

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 4.2 (Hardening Coverage)' do
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

  describe 'edge cases: envelope + eval error paths' do
    it 'rejects msgpack payload that is not a map' do
      bytes = MessagePack.pack(['not', 'a', 'map'])
      expect do
        NewBridge::Envelope.decode(bytes)
      end.to raise_error(NewBridge::Envelope::Error, /expected a map/)
    end

    it 'rejects malformed envelope bytes' do
      expect do
        NewBridge::Envelope.decode("\x81\xA4type".b)
      end.to raise_error(NewBridge::Envelope::Error)
    end

    it 'rejects envelope with unknown keys on encode' do
      expect do
        NewBridge::Envelope.encode(
          'call_id' => 'abc',
          'type' => 'REQ',
          'bogus' => 'x'
        )
      end.to raise_error(NewBridge::Envelope::InvalidEnvelope, /unknown keys/)
    end

    it 'rejects empty envelope bytes' do
      expect do
        NewBridge::Envelope.decode(''.b)
      end.to raise_error(NewBridge::Envelope::InvalidEnvelope, /empty envelope/)
    end

    it 'raises on invalid R syntax' do
      expect do
        @client.eval_r('x <-')
      end.to raise_error(NewBridge::SessionClient::RProcessError)
    end

    it 'raises on empty R code payload' do
      expect do
        @client.eval_r('')
      end.to raise_error(NewBridge::SessionClient::RProcessError)
    end

    it 'returns nil JSON value for NA integer scalar' do
      out = @client.eval_r('as.integer(NA)')
      expect(out['kind']).to eq('integer')
      expect(out['value']).to be_nil
    end

    it 'returns nil JSON value for NA logical scalar' do
      out = @client.eval_r('as.logical(NA)')
      expect(out['kind']).to eq('logical')
      expect(out['value']).to be_nil
    end

    it 'returns nil JSON value for NA double scalar' do
      out = @client.eval_r('as.numeric(NA)')
      expect(out['kind']).to eq('double')
      expect(out['value']).to be_nil
    end

    it 'raises on non scalar results' do
      expect do
        @client.eval_r('1:3')
      end.to raise_error(NewBridge::SessionClient::RProcessError, /length-1 scalar/)
    end

    it 'handles very short timeout from Ruby side' do
      expect do
        @client.eval_r('Sys.sleep(0.2); 1L', timeout: 0.05)
      end.to raise_error(NewBridge::SessionClient::TimeoutError)
    end
  end

  describe 'concurrency and stress on one instance' do
    it 'handles 50 concurrent requests with unique sessions' do
      threads = 50.times.map do |i|
        Thread.new do
          sid = "p42-conc-#{i}"
          @client.eval_r("v <- #{i}L; v", session_id: sid)['value']
        end
      end

      values = threads.map(&:value)
      expect(values.sort).to eq((0..49).to_a)
    end

    it 'handles repeated calls in same session without leaking type info' do
      sid = 'p42-same-session'
      20.times do |i|
        @client.eval_r("x <- #{i}L", session_id: sid)
      end
      out = @client.eval_r('x', session_id: sid)
      expect(out['kind']).to eq('integer')
      expect(out['value']).to eq(19)
    end

    it 'supports larger payload code strings' do
      big = 'a' * 20_000
      code = "nchar('#{big}')"
      out = @client.eval_r(code)
      expect(out['value']).to eq(20_000)
    end

    it 'keeps nested callback recursion stable for depth 5' do
      cb_call_id = @client.register_callback do |_payload, call_id|
        acc = 0
        5.times do |i|
          r = @client.eval_r("#{i}L + 1L", parent_id: call_id)
          acc += r['value']
        end
        acc
      end

      out = @client.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', 'unused', 5000)")
      expect(out['kind']).to eq('double')
      expect(out['value']).to eq(15)
    end

    it 'handles 200 sequential requests without state corruption' do
      sid = 'p42-seq'
      200.times do |i|
        @client.eval_r("k <- #{i}L", session_id: sid)
      end
      out = @client.eval_r('k', session_id: sid)
      expect(out['value']).to eq(199)
    end

    it 'supports concurrent requests to the same session deterministically for last write readback' do
      sid = 'p42-same-session-concurrent'
      threads = 20.times.map do |i|
        Thread.new { @client.eval_r("x <- #{i}L", session_id: sid) }
      end
      threads.each(&:join)
      out = @client.eval_r('x', session_id: sid)
      expect(out['kind']).to eq('integer')
      expect(out['value']).to be_between(0, 19).inclusive
    end
  end

  describe 'multi-instance hardening on current pool API' do
    before(:all) do
      cpp = File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)
      @pool = NewBridge::InstancePoolClient.new(
        source_path: cpp,
        instances: ['p42-a', 'p42-b']
      ).start
    end

    after(:all) do
      @pool&.stop
    end

    it 'maintains session isolation across instances with same session_id' do
      @pool.eval_r('x <- 101L', session_id: 'same-sid', instance_id: 'p42-a')
      @pool.eval_r('x <- 202L', session_id: 'same-sid', instance_id: 'p42-b')

      a = @pool.eval_r('x', session_id: 'same-sid', instance_id: 'p42-a')
      b = @pool.eval_r('x', session_id: 'same-sid', instance_id: 'p42-b')

      expect(a['value']).to eq(101)
      expect(b['value']).to eq(202)
    end

    it 'handles 80 pool requests under mixed concurrency' do
      threads = 8.times.map do |t|
        Thread.new do
          inst = t.even? ? 'p42-a' : 'p42-b'
          10.times.map do |i|
            n = (t * 10) + i
            sid = "p42-pool-#{t}-#{i}"
            @pool.eval_r("z <- #{n}L; z", session_id: sid, instance_id: inst)['value']
          end
        end
      end

      values = threads.flat_map(&:value)
      expect(values.sort).to eq((0..79).to_a)
    end

    it 'raises when routing to unknown instance_id' do
      expect do
        @pool.eval_r('1L + 1L', session_id: 'x', instance_id: 'unknown-instance')
      end.to raise_error(KeyError)
    end

    it 'keeps instance local state isolated after updates on both instances' do
      @pool.eval_r('counter <- 1L', session_id: 'iso', instance_id: 'p42-a')
      @pool.eval_r('counter <- 10L', session_id: 'iso', instance_id: 'p42-b')

      @pool.eval_r('counter <- counter + 1L', session_id: 'iso', instance_id: 'p42-a')
      @pool.eval_r('counter <- counter + 1L', session_id: 'iso', instance_id: 'p42-b')

      a = @pool.eval_r('counter', session_id: 'iso', instance_id: 'p42-a')
      b = @pool.eval_r('counter', session_id: 'iso', instance_id: 'p42-b')
      expect(a['value']).to eq(2)
      expect(b['value']).to eq(11)
    end

    it 'continues serving healthy instances after an unknown-instance routing error' do
      expect do
        @pool.eval_r('1L', session_id: 'err', instance_id: 'nope')
      end.to raise_error(KeyError)

      ok = @pool.eval_r('7L + 5L', session_id: 'ok', instance_id: 'p42-a')
      expect(ok['value']).to eq(12)
    end
  end

  describe 'rapid lifecycle checks' do
    it 'supports repeated start/stop cycles' do
      5.times do
        c = NewBridge::SessionClient.new(source_path: phase1_cpp)
        c.start
        out = c.eval_r('2L + 3L')
        expect(out['value']).to eq(5)
        c.stop
      end
    end

    it 'allows stop to be called multiple times safely' do
      c = NewBridge::SessionClient.new(source_path: phase1_cpp)
      c.start
      c.stop
      expect { c.stop }.not_to raise_error
    end
  end
end

