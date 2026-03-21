# frozen_string_literal: true

# Phase 5.1 smoke: verify R.bridge seam can route to NewBridge adapter.
# Run: GALAAZ_BRIDGE_IMPL=new_bridge bundle exec rspec specs/new_bridge/integration_phase5_1_smoke_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../../lib/R_interface/r'

RSpec.describe 'Phase 5.1 integration smoke (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new_bridge seam' unless ENV['GALAAZ_BRIDGE_IMPL'] == 'new_bridge'
  end

  it 'routes R.bridge to NewBridgeAdapter when configured' do
    expect(R.bridge).to be_a(R::NewBridgeAdapter)
    expect(R.bridge.ready?).to eq(true)
  end

  it 'supports basic eval_r through seam' do
    out = R.bridge.eval_r('1L + 1L')
    expect(out).to include('2')
  end

  it 'supports basic eval_r_with_result through seam' do
    env = R.bridge.eval_r_with_result('g2_v_p51 <- 123L')
    expect(env).not_to be_nil
    expect(env[:type]).to eq(:scalar_integer)
    expect(env[:value]).to eq(123)
  end
end

