# frozen_string_literal: true

require 'galaaz'

describe 'dispatch_probe per-handle cache (Phase 3)' do
  it 'reuses cached probe for the same object and method name' do
    df = R.data__frame(a: R.c(1, 2, 3))
    bridge = R.bridge
    calls = 0
    allow(bridge).to receive(:dispatch_probe).and_wrap_original do |m, h, n|
      calls += 1
      m.call(h, n)
    end

    R::Support.reset_dispatch_probe_cache_stats!
    R::Support.clear_dispatch_probe_handle_cache!

    x1 = df.a
    x2 = df.a
    expect(x1.unboxed_get(0)).to eq(1)
    expect(x2.unboxed_get(0)).to eq(1)
    expect(calls).to eq(1)
    expect(R::Support.dispatch_probe_cache_hits).to be >= 1
    expect(R::Support.dispatch_probe_cache_misses).to eq(1)
  end

  it 'does not use handle cache for R.foo module calls (no probe)' do
    bridge = R.bridge
    allow(bridge).to receive(:dispatch_probe).and_call_original

    R::Support.reset_dispatch_probe_cache_stats!
    R::Support.clear_dispatch_probe_handle_cache!

    R.c(1, 2)
    R.c(3, 4)
    expect(bridge).not_to have_received(:dispatch_probe)
  end
end
