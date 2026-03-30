# frozen_string_literal: true

require 'galaaz'

describe 'Language and expression semantics' do
  context 'symbol conversion and expression building' do
    before(:each) do
      R.len = 10
      R.sd = 20
      R.x = 5
    end

    it "converts Ruby Symbol to R symbol with unary '+'" do
      sym = +:len
      expect(sym).to be_a(R::RSymbol)
      expect(sym.to_s).to eq('len')
      expect(sym.eval).to eq 10
    end

    it 'builds language expressions from symbol arithmetic' do
      expr = :len + :sd + 5
      expect(expr).to be_a(R::Language)
      expect(expr.to_s).to eq('len + sd + 5L')
      expect(expr.eval).to eq R.c(35)
    end

    it 'supports comparison operators in expressions' do
      df = R.data__frame(a: (1..5), b: (5..1))
      e = :a > :b
      expect(e.to_s).to eq('a > b')
      expect(e.eval(df)).to eq R.c(false, false, false, true, true)
    end

    it 'supports quoted function construction through E helper' do
      exp = E.sin(:len)
      expect(exp).to be_a(R::Language)
      expect(exp.to_s).to eq('sin(len)')
      expect(exp.eval).to eq R.c(Math.sin(10))
    end
  end

  context 'evaluation with context objects' do
    it 'evaluates composite arithmetic expression in list context' do
      ctx = R.list(a: 10, b: 20, c: 30)
      val = R.eval(:a + :b * :c, ctx)
      expect(val).to eq 610
    end

    it 'evaluates expression against global binding when no context is provided' do
      R.x = 5
      expect(R.eval(:x + 10)).to eq 15
    end

    it 'evaluates expression in list context via R.eval(expr, ctx)' do
      ctx = R.list(x: 20)
      val = R.eval(:x + 10, ctx)
      expect(val).to be_a(R::Vector)
      expect(val >> 0).to eq 30
    end

    it 'uses expression predicates in subset()' do
      df = R.data__frame(a: (1..5), b: (5..1), c: R.c(5, 3, 1, 4, 1))
      sub = R.subset(df, :a >= 4)
      expect(sub).to be_a(R::DataFrame)
      expect(sub.nrow >> 0).to eq 2
      expect(sub[1, 1]).to eq 4
      expect(sub[2, 2]).to eq 1
    end
  end

  context 'reintroduced rlang helper APIs' do
    before(:all) do
      ok = R::Support.eval("requireNamespace('rlang', quietly=TRUE)")
      skip 'R package rlang is not available' unless ok == true
    end

    it 'supports R.expr for symbol construction' do
      R.len = 10
      exp = R.expr(:len)
      expect(exp).to be_a(R::RSymbol)
      expect(exp.eval).to eq 10
    end

    it 'supports R.expr for boolean literals' do
      expect(R.expr(true)).to eq R.c(true)
      expect(R.expr(false)).to eq R.c(false)
    end

    it 'supports R.call2 for call construction' do
      e = R.call2('mean', x: +:x, na__rm: true)
      expect(e).to be_a(R::Language)
      expect(e.to_s).to eq('mean(x = x, na.rm = TRUE)')
    end

    it 'supports R.call2 for assignment calls' do
      e = R.call2('<-', R.expr(:x), 10)
      e.eval
      expect(~:x).to eq 10
    end

    it 'supports R.exec for dynamic function execution' do
      val = R.exec('mean', x: (1..10), na__rm: true, trim: 0.1)
      expect(val).to eq 5.5
    end

    it 'supports R.exec with splatted argument hashes' do
      args = [x: (1..10), na__rm: true, trim: 0.1]
      expect(R.exec('mean', *args)).to eq 5.5
    end
  end
end
