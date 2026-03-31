# frozen_string_literal: true

require 'galaaz'

describe 'NewBridge callback timeout configuration' do
  it 'embeds GALAAZ_CALLBACK_TIMEOUT_MS into callback stub wait time' do
    old = ENV['GALAAZ_CALLBACK_TIMEOUT_MS']
    ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = '123456'

    begin
      stub = R.bridge.register_callback_proc_stub(proc { |_x| nil })
      expect(stub).to include('galaaz_callback_call_phase3')
      expect(stub).to include('123456')
    ensure
      ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = old
    end
  end

  it 'uses GALAAZ_BRIDGE_TIMEOUT_SEC as default eval timeout' do
    old = ENV['GALAAZ_BRIDGE_TIMEOUT_SEC']
    ENV['GALAAZ_BRIDGE_TIMEOUT_SEC'] = '321'

    begin
      client = R.bridge.instance_variable_get(:@client)
      captured = nil
      allow(client).to receive(:eval_r).and_wrap_original do |m, *args, **kwargs|
        captured = kwargs[:timeout]
        m.call(*args, **kwargs)
      end

      R.bridge.eval_r('1+1')
      expect(captured).to eq(321)
    ensure
      ENV['GALAAZ_BRIDGE_TIMEOUT_SEC'] = old
    end
  end

  it 'uses GALAAZ_BRIDGE_TIMEOUT_SEC in session helper evals' do
    old = ENV['GALAAZ_BRIDGE_TIMEOUT_SEC']
    ENV['GALAAZ_BRIDGE_TIMEOUT_SEC'] = '321'

    begin
      client = R.bridge.instance_variable_get(:@client)
      captured = nil
      allow(client).to receive(:eval_r).and_wrap_original do |m, *args, **kwargs|
        captured = kwargs[:timeout] if args[0].to_s.include?('galaaz_assign_session')
        m.call(*args, **kwargs)
      end

      R.bridge.assign_session('spec_session', 'spec_key', '1L')
      expect(captured).to eq(321)
    ensure
      ENV['GALAAZ_BRIDGE_TIMEOUT_SEC'] = old
    end
  end

  it 'does not clear callback timeout env when no per-call override is provided' do
    old = ENV['GALAAZ_CALLBACK_TIMEOUT_MS']
    ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = '7200000'

    begin
      R.with_callback_timeout_ms(nil) { 1 + 1 }
      expect(ENV['GALAAZ_CALLBACK_TIMEOUT_MS']).to eq('7200000')
    ensure
      ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = old
    end
  end
end

