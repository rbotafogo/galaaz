# frozen_string_literal: true

# Phase 5.4 nested callback + session scoping integration.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_4_nested_session_callbacks_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.4 integration nested callbacks with session scoping' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new bridge (avoid GALAAZ_BRIDGE_IMPL=shadow)' if R.shadow_bridge_selected?
  end

  it 'keeps nested callback writes isolated to the active session' do
    bridge = R.bridge
    expect(bridge).to respond_to(:with_session)

    out_a = bridge.with_session('nested-sess-a') do
      bridge.eval_r('call_me <- function(f) { f() }')
      R.call_me(proc do |_payload, _call_id|
        bridge.eval_r_with_result('g2_v_ns <- 111L')
        bridge.eval_r_with_result('g2_v_read <- g2_v_ns')[:value]
      end)
    end

    out_b = bridge.with_session('nested-sess-b') do
      bridge.eval_r('call_me <- function(f) { f() }')
      R.call_me(proc do |_payload, _call_id|
        bridge.eval_r_with_result('g2_v_ns <- 222L')
        bridge.eval_r_with_result('g2_v_read <- g2_v_ns')[:value]
      end)
    end

    read_a = bridge.with_session('nested-sess-a') do
      bridge.eval_r_with_result('g2_v_read <- g2_v_ns')[:value]
    end

    read_b = bridge.with_session('nested-sess-b') do
      bridge.eval_r_with_result('g2_v_read <- g2_v_ns')[:value]
    end

    expect(out_a).to be_a(R::Object)
    expect(out_b).to be_a(R::Object)
    expect(read_a).to eq(111)
    expect(read_b).to eq(222)
  end
end

