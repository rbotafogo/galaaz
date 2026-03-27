# frozen_string_literal: true

# Phase 5.3 callback edge cases on the R.bridge seam.
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_3_edge_cases_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../../lib/R_interface/r'

RSpec.describe 'Phase 5.3 integration callback edge cases (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new_bridge seam' unless ENV['GALAAZ_BRIDGE_IMPL'] == 'new_bridge'
    R.bridge.eval_r('call_me <- function(f) { f() }')
    R.bridge.eval_r('call_with_arg <- function(f, x) { f(x) }')
  end

  it 'supports callback proc with arity 2 receiving payload and call_id' do
    result = R.call_with_arg(proc { |payload, call_id|
      payload.to_i + (call_id.to_s.empty? ? 0 : 1)
    }, 41)

    expect(result).to be_a(R::Object)
    expect(result.to_ruby).to eq(42.0)
  end

  it 'passes logical scalar argument through payload conversion' do
    result = R.call_with_arg(proc { |x| x.to_s == 'TRUE' ? 7 : 0 }, true)
    expect(result.to_ruby).to eq(7.0)
  end

  it 'keeps nested eval path available inside callback with arity 2' do
    bridge = R.bridge
    inner = nil

    out = R.call_me(proc { |_payload, _call_id|
      inner = bridge.eval_r_with_result('g2_v_p53_edge <- 55L')
      9
    })

    expect(out).to be_a(R::Object)
    expect(out.to_ruby).to eq(9.0)
    expect(inner).not_to be_nil
    expect(inner[:type]).to eq(:scalar_integer)
    expect(inner[:value]).to eq(55)
  end

  it 'handles non-scalar callback argument deterministically' do
    # For non-scalar args, the current seam intentionally sends empty payload.
    result = R.call_with_arg(proc { |x| x.to_s.empty? ? 1 : 0 }, R.c(1, 2, 3))
    expect(result.to_ruby).to eq(1.0)
  end
end

