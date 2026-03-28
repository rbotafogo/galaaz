# frozen_string_literal: true

# Phase 5.1 seam check for basic R module call path (no callbacks).
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_1_r_api_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.1 integration basic R API (no callbacks)' do
  it 'supports simple R function dispatch through R::Support' do
    result = R.sum(R.c(1, 2, 3))
    expect(result).to be_a(R::Object)
    expect(result.to_ruby).to eq(6)
  end

  it 'supports handle-producing calls and follow-up scalar access' do
    vec = R.c(10, 20, 30)
    expect(vec).to be_a(R::Object)

    size = R.length(vec)
    expect(size.to_ruby).to eq(3)
  end
end

