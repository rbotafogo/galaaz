# frozen_string_literal: true

require 'galaaz'

module ScopedSymbolDslWithUsing
  using Galaaz::SymbolDSL

  def self.build_expr
    :a + :b + 5
  end

  def self.fetch_symbol
    ~:letters
  end
end

module ScopedSymbolDslWithoutUsing
  def self.build_expr
    :a + :b + 5
  end
end

describe 'Scoped Symbol DSL refinement' do
  it 'enables symbol expression DSL inside lexical using scope' do
    expr = ScopedSymbolDslWithUsing.build_expr
    expect(expr).to be_a(R::Language)
    expect(expr.to_s).to eq('a + b + 5L')
  end

  it 'enables unary symbol fetch inside lexical using scope' do
    vec = ScopedSymbolDslWithUsing.fetch_symbol
    expect(vec).to be_a(R::Vector)
    expect(vec[1]).to eq('a')
  end

  it 'does not enable symbol expression DSL outside using scope' do
    expect { ScopedSymbolDslWithoutUsing.build_expr }.to raise_error(NoMethodError)
  end
end

