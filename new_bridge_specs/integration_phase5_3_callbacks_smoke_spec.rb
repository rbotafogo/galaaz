# frozen_string_literal: true

# Phase 5.3 callback/proc stub smoke on the R.bridge seam.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_3_callbacks_smoke_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.3 integration callbacks smoke (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
  end

  it 'invokes a Ruby Proc from R and returns a scalar result' do
    R.bridge.eval_r('call_me <- function(f) { f() }')
    result = R.call_me(proc { 42.0 })
    expect(result).to be_a(R::Object)
    expect(result.to_ruby).to eq(42.0)
  end
end

