# frozen_string_literal: true

# Phase 5.3 callback error propagation on the R.bridge seam.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_3_callback_error_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.3 integration callback error (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new bridge (avoid GALAAZ_BRIDGE_IMPL=shadow)' if R.shadow_bridge_selected?
    R.bridge.eval_r('call_me <- function(f) { f() }')
  end

  it 'propagates Ruby callback failure through bridge call' do
    expect do
      R.call_me(proc { raise 'p53 callback boom' })
    end.to raise_error(StandardError, /evaluation error|boom/)
  end
end

