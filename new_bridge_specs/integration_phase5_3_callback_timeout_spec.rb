# frozen_string_literal: true

# Phase 5.3 callback timeout behavior on the R.bridge seam.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_3_callback_timeout_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.3 integration callback timeout (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    R.bridge.eval_r('call_me <- function(f) { f() }')
  end

  it 'raises when callback execution exceeds callback wait (GALAAZ_CALLBACK_TIMEOUT_MS)' do
    old = ENV['GALAAZ_CALLBACK_TIMEOUT_MS']
    ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = '2000'
    begin
      expect do
        R.call_me(proc { sleep 5; 999 })
      end.to raise_error(StandardError, /timeout|evaluation error|no RET/i)
    ensure
      ENV['GALAAZ_CALLBACK_TIMEOUT_MS'] = old
    end
  end
end

