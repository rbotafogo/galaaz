# frozen_string_literal: true

# Phase 5.3 callback argument compatibility on the R.bridge seam.
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_3_callback_args_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../../lib/R_interface/r'

RSpec.describe 'Phase 5.3 integration callback args (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new_bridge seam' unless ENV['GALAAZ_BRIDGE_IMPL'] == 'new_bridge'
    R.bridge.eval_r('call_with_arg <- function(f, x) { f(x) }')
  end

  it 'passes a numeric scalar argument from R into Ruby callback' do
    result = R.call_with_arg(proc { |x| x.to_i + 1 }, 41)
    expect(result).to be_a(R::Object)
    expect(result.to_ruby).to eq(42.0)
  end

  it 'passes a character scalar argument from R into Ruby callback' do
    result = R.call_with_arg(proc { |x| x.to_s.upcase == 'ABC' ? 1 : 0 }, 'abc')
    expect(result).to be_a(R::Object)
    expect(result.to_ruby).to eq(1.0)
  end
end

