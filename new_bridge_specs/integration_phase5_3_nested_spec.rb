# frozen_string_literal: true

# Phase 5.3 nested callback integration on the R.bridge seam.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_3_nested_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.3 integration nested callbacks (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
  end

  it 'supports nested eval_r_with_result from inside callback and returns correct values' do
    bridge = R.bridge
    inner_envelope = nil

    result = R.lapply(R.c(1), proc do |_x|
      inner_envelope = bridge.eval_r_with_result('g2_v_inner <- 200L')
      33
    end)

    expect(inner_envelope).not_to be_nil
    expect(inner_envelope[:type]).to eq(:scalar_integer)
    expect(inner_envelope[:value]).to eq(200)
    expect(result).to be_a(R::Object)
  end
end

