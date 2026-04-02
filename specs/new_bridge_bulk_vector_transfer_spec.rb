# frozen_string_literal: true

require 'galaaz'

describe 'NewBridge bulk vector pull (__G_PULL_VECTOR__)' do
  it 'pulls full integer vector in one gatekeeper call' do
    client = R.bridge.instance_variable_get(:@client)
    bulk_cmds = []
    allow(client).to receive(:eval_r).and_wrap_original do |m, code, **kwargs|
      bulk_cmds << code.to_s if code.to_s.start_with?('__G_PULL_VECTOR__')
      m.call(code, **kwargs)
    end

    v = R.c(7, 8, 9)
    arr = v >> nil
    expect(arr).to eq([7, 8, 9])
    expect(bulk_cmds.any? { |c| c =~ /\A__G_PULL_VECTOR__\|g2_v\d+\z/ }).to eq(true)
  end

  it 'pulls double vector with NA as nil' do
    h = R::Support.generate_var_name
    R.bridge.eval_r("#{h} <- c(1.0, NA_real_, 3.0)")
    arr = R.bridge.pull_vector(h)
    expect(arr[0]).to eq(1.0)
    expect(arr[1]).to be_nil
    expect(arr[2]).to eq(3.0)
  end

  it 'pulls logical vector with NA mapped to R::NA' do
    v = R.c(true, false, R::NA)
    arr = v >> nil
    expect(arr[0]).to eq(true)
    expect(arr[1]).to eq(false)
    expect(arr[2]).to eq(R::NA)
  end

  it 'pulls character vector with NA as nil' do
    v = R.c('x', 'y')
    arr = v >> nil
    expect(arr).to eq(%w[x y])
  end

  it 'matches elementwise pull for medium-length numeric vector' do
    n = 500
    h = R::Support.generate_var_name
    R.bridge.eval_r("#{h} <- 1:#{n}")
    bridge = R.bridge
    bulk = bridge.pull_vector(h)
    elementwise = bridge.send(:pull_vector_elementwise, h)
    expect(bulk.size).to eq(n)
    expect(bulk).to eq(elementwise)
  end

  it 'pull_integer_vector slice matches elementwise' do
    h = R::Support.generate_var_name
    R.bridge.eval_r("#{h} <- 10:19")
    bridge = R.bridge
    slice = bridge.pull_integer_vector(h, 10, 2, 4)
    expect(slice).to eq([12, 13, 14, 15])
    slow = bridge.send(:pull_integer_vector_elementwise, h, 2, 4)
    expect(slice).to eq(slow)
  end

  it 'pull_double_vector slice matches elementwise for doubles' do
    h = R::Support.generate_var_name
    R.bridge.eval_r("#{h} <- as.numeric(1:5) + 0.5")
    bridge = R.bridge
    slice = bridge.pull_double_vector(h, 5, 1, 3)
    expect(slice.size).to eq(3)
    slow = bridge.send(:pull_double_vector_elementwise, h, 1, 3)
    expect(slice).to eq(slow)
  end
end
