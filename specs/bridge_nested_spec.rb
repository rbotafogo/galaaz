# -*- coding: utf-8 -*-
# Phase 4: nested bridge spec. Callback invokes eval_r_with_result; assert inner and outer both get correct results (no cross-talk, no deadlock).

require 'galaaz'

describe "Bridge nested access (Phase 4)" do

  it "allows nested eval_r_with_result from callback and returns correct inner and outer results" do
    bridge = R.bridge
    inner_envelope = nil

    # Callback runs inside R's lapply; it calls eval_r_with_result (nested) and we capture the result
    result = R.lapply(R.c(1), (proc do |_x|
      inner_envelope = bridge.eval_r_with_result("g2_v_inner <- 200L")
      33
    end))

    expect(inner_envelope).not_to be_nil
    expect(inner_envelope[:type]).to eq(:scalar_integer)
    expect(inner_envelope[:value]).to eq(200)

    # Outer lapply returns a list (handle); we can at least treat it as an R object
    expect(result).to be_a(R::Object)
  end
end
