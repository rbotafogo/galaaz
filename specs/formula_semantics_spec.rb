# frozen_string_literal: true

require 'galaaz'

describe 'Formula semantics' do
  context 'formula construction' do
    it 'builds formulas from string and DSL' do
      f1 = R.formula('mpg ~ wt + cyl')
      expect(f1.to_s.lines.first.chomp).to eq('mpg ~ wt + cyl')

      f2 = :mpg.til :wt + :cyl
      expect(f2.to_s.lines.first.chomp).to eq('mpg ~ wt + cyl')
    end

    it 'builds interaction formulas with operators' do
      f1 = :y.til :x * :x2
      expect(f1.to_s.lines.first.chomp).to eq('y ~ x * x2')

      f2 = :y.til :x + :x2 + (:x.inter :x2)
      expect(f2.to_s.lines.first.chomp).to eq('y ~ x + x2 + x:x2')

      f3 = :y.til :a + (:b._ :in, :a)
      expect(f3.to_s.lines.first.chomp).to eq('y ~ a + b %in% a')
    end
  end

  context 'model.frame and lm with formula' do
    it 'builds model frame with deterministic values under set.seed' do
      R.set__seed(123)
      x = R.rnorm(5)
      x2 = R.rnorm(5)
      y = R.rnorm(5)

      formula = :y.til :x * :x2
      model = R.model__frame(formula, data: R.data__frame(x: x, y: y, x2: x2))

      expect((model[1, 1] >> 0)).to be_within(1e-9).of(1.2240817974394615)
      expect((model[1, 3] >> 0)).to be_within(1e-9).of(1.715064986883281)
      expect((model[3, 2] >> 0)).to be_within(1e-9).of(1.558708314149124)
      expect((model[5, 1] >> 0)).to be_within(1e-9).of(-0.5558411347540749)
    end

    it 'fits lm on mtcars and predicts expected trend values' do
      fit = R.lm((:mpg.til :wt + :cyl), data: :mtcars)
      expect((fit.coefficients[[1]] >> 0)).to be_within(1e-9).of(39.68626148025295)
      expect((fit.coefficients[['wt']] >> 0)).to be_within(1e-9).of(-3.190972138983746)
      expect((fit.coefficients[['cyl']] >> 0)).to be_within(1e-9).of(-1.507794968259798)

      pred = R.predict(fit, R.data__frame(wt: R.c(3.0, 2.0), cyl: R.c(6.0, 4.0)))
      expect((pred[1] >> 0)).to be_within(1e-9).of(21.066575253742926)
      expect((pred[2] >> 0)).to be_within(1e-9).of(27.273137329246268)
    end
  end
end
