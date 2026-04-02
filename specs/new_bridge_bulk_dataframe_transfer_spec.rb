# frozen_string_literal: true

require 'galaaz'

describe 'NewBridge bulk data.frame pull (column-wise + pull_vector)' do
  it 'unboxes data.frame to Ruby hash with correct columns' do
    df = R.data__frame(x: R.c(1, 2, 3), y: R.c('a', 'b', 'c'))
    ruby = df.to_ruby
    expect(ruby).to be_a(Hash)
    expect(ruby['x']).to eq([1, 2, 3])
    expect(ruby['y']).to eq(%w[a b c])
  end

  it 'preserves NA in numeric and logical columns' do
    h = R::Support.generate_var_name
    R.bridge.eval_r("#{h} <- data.frame(a = c(1, NA_real_), b = c(TRUE, NA), stringsAsFactors = FALSE)")
    raw = R.bridge.pull_dataframe(h)
    expect(raw['a'][0]).to eq(1.0)
    expect(raw['a'][1]).to be_nil
    expect(raw['b'][0]).to eq(true)
    expect(raw['b'][1]).to eq(R::NA)
  end

  it 'uses one bulk pull per atomic column (not per cell)' do
    client = R.bridge.instance_variable_get(:@client)
    bulk = 0
    allow(client).to receive(:eval_r).and_wrap_original do |m, code, **kwargs|
      bulk += 1 if code.to_s.start_with?('__G_PULL_VECTOR__')
      m.call(code, **kwargs)
    end

    df = R.data__frame(u: R.c(10, 20), v: R.c(1.5, 2.5), w: R.c(true, false))
    df.to_ruby
    expect(bulk).to eq(3)
  end

  it 'matches manual column bind for zero-row data.frame' do
    h = R::Support.generate_var_name
    R.bridge.eval_r("#{h} <- data.frame(x = numeric(0), y = character(0), stringsAsFactors = FALSE)")
    raw = R.bridge.pull_dataframe(h)
    expect(raw['x']).to eq([])
    expect(raw['y']).to eq([])
  end
end
