# frozen_string_literal: true

# Phase 5.4 session routing integration on the R.bridge seam.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_4_session_routing_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.4 integration session routing (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
  end

  it 'keeps same handle name isolated across sessions' do
    bridge = R.bridge
    expect(bridge).to respond_to(:with_session)

    a_value = bridge.with_session('sess-a') do
      bridge.eval_r_with_result('g2_v_shared <- 10L')
      bridge.eval_r_with_result('g2_v_read <- g2_v_shared')[:value]
    end

    b_value = bridge.with_session('sess-b') do
      bridge.eval_r_with_result('g2_v_shared <- 20L')
      bridge.eval_r_with_result('g2_v_read <- g2_v_shared')[:value]
    end

    again_a = bridge.with_session('sess-a') do
      bridge.eval_r_with_result('g2_v_read <- g2_v_shared')[:value]
    end

    expect(a_value).to eq(10)
    expect(b_value).to eq(20)
    expect(again_a).to eq(10)
  end
end

