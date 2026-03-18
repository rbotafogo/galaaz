# frozen_string_literal: true

# Phase 3: R -> Ruby callbacks via CALL/RET.
# Run: bundle exec rspec specs/new_bridge/phase3_callbacks_spec.rb

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 3 (CALL/RET callbacks)' do
  let(:phase1_cpp) { File.expand_path('../../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__) }
  let(:phase1_so)  { File.expand_path('../../ext/new_bridge/galaaz_gatekeeper.so', __dir__) }

  def with_client(cpp, instance_id: 'instance-a')
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')

    # Always use .cpp with sourceCpp for now
    c = NewBridge::SessionClient.new(source_path: cpp)
    c.start
    yield c, instance_id
  ensure
    c&.stop
  end

  it 'callback ping: Ruby callback returns a scalar' do
    with_client(phase1_cpp) do |c, iid|
      cb_call_id = c.register_callback do |payload|
        payload.to_i + 1
      end

      out = c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', '41', 500)",
                      session_id: 'sess-a', instance_id: iid)

      expect(out['kind']).to eq('double')
      expect(out['value']).to eq(42)
    end
  end

  it 'callback error propagation: Ruby callback raises' do
    with_client(phase1_cpp) do |c, iid|
      cb_call_id = c.register_callback do |_payload|
        raise 'boom'
      end

      expect do
        c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', '0', 500)",
                 session_id: 'sess-a', instance_id: iid)
      end.to raise_error(NewBridge::SessionClient::RProcessError, /evaluation error/)
    end
  end

  it 'callback timeout: Ruby callback does not respond in time' do
    with_client(phase1_cpp) do |c, iid|
      cb_call_id = c.register_callback do |_payload|
        sleep 0.2
        999
      end

      expect do
        c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', '0', 50)",
                 session_id: 'sess-a', instance_id: iid, timeout: 2)
      end.to raise_error(NewBridge::SessionClient::RProcessError, /evaluation error|timeout/)
    end
  end
end

