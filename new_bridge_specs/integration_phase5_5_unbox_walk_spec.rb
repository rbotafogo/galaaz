# frozen_string_literal: true

# Phase 5.5 specialized unbox_walk traversal semantics.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_5_unbox_walk_spec.rb


require 'timeout'
require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.5 integration unbox_walk (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
  end

  it 'reports depth_limit for deeply nested lists in one probe call' do
    bridge = R.bridge
    expect(bridge).to respond_to(:unbox_walk)

    deep = R.list(1)
    (R::Support::MAX_UNBOX_DEPTH + 10).times { deep = R.list(deep) }

    result = Timeout.timeout(10) do
      bridge.unbox_walk(deep.r_interop,
                        max_depth: R::Support::MAX_UNBOX_DEPTH,
                        max_nodes: 300_000)
    end

    expect(result[:status]).to eq(:depth_limit)
    expect(result[:max_depth]).to be > R::Support::MAX_UNBOX_DEPTH
  end

  it 'materializes nested list/scalar trees in one call when supported' do
    bridge = R.bridge
    expect(bridge).to respond_to(:unbox_materialize)

    tree = R.list(R.list(1, 2), R.list(3, 4))
    result = bridge.unbox_materialize(tree.r_interop,
                                      max_depth: R::Support::MAX_UNBOX_DEPTH,
                                      max_nodes: 300_000)

    expect(result[:status]).to eq(:ok)
    expect(result[:value]).to eq([[1, 2], [3, 4]])
  end
end

