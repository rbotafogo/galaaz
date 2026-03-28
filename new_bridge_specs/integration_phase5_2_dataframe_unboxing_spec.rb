# frozen_string_literal: true

# Phase 5.2 data.frame unboxing compatibility.
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_2_dataframe_unboxing_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.2 integration data.frame unboxing' do
  it 'unboxes a tiny data.frame handle returned by R::Support into a Ruby hash' do
    df = R.data__frame(x: R.c(1, 2), y: R.c('a', 'b'))
    ruby = df.to_ruby
    expect(ruby).to be_a(Hash)
    expect(ruby['x']).to eq([1, 2])
    expect(ruby['y']).to eq(['a', 'b'])
  end
end

