# frozen_string_literal: true

# Phase 5.1 seam check for eval/handle roundtrip semantics (no callbacks).
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_1_eval_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.1 integration eval semantics (no callbacks)' do
  it 'evaluates scalar expression through R::Support.eval' do
    value = R::Support.eval('1L + 2L')
    expect(value).to eq(3)
  end
end

