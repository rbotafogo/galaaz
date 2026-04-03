# frozen_string_literal: true

# Async Ruby→R completion (+eval_r_async+, +R.eval_r_async+, +R::Async+).
# Run: bin/run_all_rspec new_bridge_specs/eval_r_async_spec.rb

require 'thread'

require_relative '../lib/new_bridge'
require_relative '../lib/R_interface/r'

RSpec.describe 'NewBridge::SessionClient#eval_r_async' do
  cpp = File.expand_path('../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)

  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    @client = NewBridge::SessionClient.new(source_path: cpp)
    @client.start
  end

  after(:all) { @client&.stop }

  it 'returns call_id immediately and completes with success payload' do
    done = Queue.new
    cid = @client.eval_r_async('42L', timeout: nil) do |result|
      done.push(result)
    end
    expect(cid).to match(/\A[0-9a-f-]{36}\z/i)

    r = done.pop
    expect(r).to be_ok
    expect(r.value['kind']).to eq('integer')
    expect(r.value['value']).to eq(42)
  end

  it 'runs Ruby work before R completion when R sleeps' do
    order = Queue.new
    @client.eval_r_async('({ Sys.sleep(0.15); 1L })', timeout: nil) do |result|
      order.push [:r_done, result.ok?]
    end
    order.push [:ruby_after_start]
    sleep 0.05
    order.push [:ruby_mid]

    expect(order.pop).to eq([:ruby_after_start])
    expect(order.pop).to eq([:ruby_mid])
    expect(order.pop).to eq([:r_done, true])
  end

  it 'completes with failure on Ruby-side timeout' do
    done = Queue.new
    @client.eval_r_async('({ Sys.sleep(0.3); 1L })', timeout: 0.05) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).not_to be_ok
    expect(r.error).to be_a(NewBridge::SessionClient::TimeoutError)
  end

  it 'completes with failure on R error' do
    done = Queue.new
    @client.eval_r_async('stop("galaaz_async_test_error")', timeout: nil) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).not_to be_ok
    expect(r.error).to be_a(NewBridge::SessionClient::RProcessError)
    expect(r.error.message).to match(/galaaz_async_test_error/)
  end

  it 'raises without a block' do
    expect { @client.eval_r_async('1L') }.to raise_error(ArgumentError, /block/)
  end
end

RSpec.describe 'R.eval_r_async and R::Async (integration)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
  end

  it 'formats scalar like sync eval_r' do
    done = Queue.new
    R.eval_r_async('({ Sys.sleep(0.05); 7L })', timeout: nil) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).to be_ok
    expect(r.value).to eq('[1] 7')
  end

  it 'R::Async returns an R::Object for rnorm(1)' do
    done = Queue.new
    R::Async.rnorm(1) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).to be_ok
    expect(r.value).to be_a(R::Object)
  end

  it 'R::Async accepts timeout: and fails when R is too slow' do
    done = Queue.new
    R::Async.Sys__sleep(0.3, timeout: 0.05) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).not_to be_ok
    expect(r.error).to be_a(NewBridge::SessionClient::TimeoutError)
  end

  it 'raises when R::Async is called without a block' do
    expect { R::Async.rnorm(1) }.to raise_error(ArgumentError, /block/)
  end
end
