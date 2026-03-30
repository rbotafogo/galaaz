# frozen_string_literal: true

require 'galaaz'

describe 'Session env bridge helpers' do
  it 'ensures, assigns, gets, and removes values in a session-scoped env' do
    bridge = R.bridge
    skip 'session env API available only on NewBridge adapter' unless bridge.respond_to?(:ensure_session_env)

    sid = "spec_sid_#{Time.now.to_i}_#{rand(1000)}"
    key = 'tmp_value'

    expect(bridge.ensure_session_env(sid)).to eq(nil)

    bridge.assign_session(sid, key, '42L')
    got = bridge.get_session(sid, key)
    expect(got['kind'].to_s).to eq('integer')
    expect(got['value']).to eq(42)

    bridge.rm_session(sid, key)
    expect do
      bridge.get_session(sid, key)
    end.to raise_error(NewBridge::SessionClient::RProcessError)
  end
end
