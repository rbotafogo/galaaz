# frozen_string_literal: true

# Phase 5.2 decoding/unboxing compatibility for eval handles.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_2_handle_eval_unboxing_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.2 integration handle eval unboxing' do
  it 'unboxes a vector handle returned by R::Support.eval' do
    vec = R.c(7, 8, 9)
    out = R::Support.eval(vec)
    expect(out).to be_a(R::Object)
    expect(out.to_ruby).to eq([7, 8, 9])
  end

  it 'unboxes a character vector handle returned by R::Support.eval' do
    vec = R.c('a', 'b')
    out = R::Support.eval(vec)
    expect(out).to be_a(R::Object)
    expect(out.to_ruby).to eq(['a', 'b'])
  end
end

