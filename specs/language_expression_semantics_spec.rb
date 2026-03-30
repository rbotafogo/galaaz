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
end
