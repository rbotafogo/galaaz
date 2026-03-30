# frozen_string_literal: true

# Phase 1 (plan): NewBridge callback argument transport + semantic return via galaaz_bridge_env.
# Fast suite — keep coverage here, not in new_bridge_specs.

require 'galaaz'

describe 'Phase 1 NewBridge callbacks (adapter proc stub)' do
  def global_callback_handles
    names = R::Support.eval("ls(envir = .GlobalEnv, pattern = '^g2_v[0-9]+$')")
    ruby = names.respond_to?(:to_ruby) ? names.to_ruby : []
    ruby.is_a?(Array) ? ruby : Array(ruby).compact
  end

  before(:all) do
    R.bridge.eval_r('call_with_arg <- function(f, x) { f(x) }')
    R.bridge.eval_r('call_twice <- function(f, a, b) { f(a); f(b) }')
  end

  it 'passes numeric scalar and returns semantic value from R' do
    result = R.call_with_arg(proc { |x| (x >> 0) + 1 }, 41)
    expect(result).to be_a(R::Object)
    expect(result.to_ruby).to eq(42.0)
  end

  it 'passes character scalar' do
    result = R.call_with_arg(proc { |x| x.to_ruby.to_s.upcase == 'ABC' ? 1 : 0 }, 'abc')
    expect(result.to_ruby).to eq(1.0)
  end

  it 'passes logical scalar' do
    result = R.call_with_arg(proc { |x| x.to_ruby == true ? 7 : 0 }, true)
    expect(result.to_ruby).to eq(7.0)
  end

  it 'passes logical NA (R NA may appear as Ruby nil at the callback boundary)' do
    na1 = R::Support.eval('NA')
    result = R.call_with_arg(proc { |x|
      (x.nil? || (x.respond_to?(:to_ruby) && x.to_ruby.nil?)) ? 1 : 0
    }, na1)
    expect(result.to_ruby).to eq(1.0)
  end

  it 'passes non-scalar argument as boxed R object' do
    result = R.call_with_arg(proc { |x| (x.length >> 0) == 3 ? 1 : 0 }, R.c(1, 2, 3))
    expect(result.to_ruby).to eq(1.0)
  end

  it 'reuses the same callback for two invocations' do
    result = R.call_twice(proc { |x| (x >> 0) + 100 }, 1, 2)
    expect(result).to be_a(R::Object)
    # Last invocation wins as return value of call_twice (f(b) with b=2 -> 102)
    expect(result.to_ruby).to eq(102.0)
  end

  it 'isolates two different callback procs' do
    r1 = R.call_with_arg(proc { |x| (x >> 0) + 1 }, 10)
    r2 = R.call_with_arg(proc { |x| (x >> 0) + 2 }, 10)
    expect(r1.to_ruby).to eq(11.0)
    expect(r2.to_ruby).to eq(12.0)
  end

  it 'does not leak temporary g2_v callback handles in .GlobalEnv' do
    before = global_callback_handles

    10.times do |i|
      out = R.call_with_arg(proc { |x| (x >> 0) + 1 }, i)
      expect(out.to_ruby).to eq((i + 1).to_f)
    end

    after = global_callback_handles
    expect(after).to eq(before)
  end
end
