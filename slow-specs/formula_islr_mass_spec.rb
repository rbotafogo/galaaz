# frozen_string_literal: true

require 'galaaz'
using Galaaz::SymbolDSL

RSpec.describe 'Formula legacy datasets (slow)' do
  before(:all) do
    begin
      R.install_and_loads('ISLR', 'MASS')
    rescue StandardError => e
      skip "ISLR/MASS not available: #{e.message}"
    end
  end

  it 'fits classic Boston regressions with expected coefficients' do
    fit = R.lm((R[:medv].til R[:lstat] + R[:age]), data: :Boston)

    expect((fit.coefficients[[1]] >> 0)).to be_within(1e-8).of(33.2227605317)
    expect((fit.coefficients[['lstat']] >> 0)).to be_within(1e-8).of(-1.0320685641)
    expect((fit.coefficients[[3]] >> 0)).to be_within(1e-8).of(0.0345443385)
  end

  it 'fits polynomial regression on Boston with stable coefficients' do
    fit = R.lm((R[:medv].til E.poly(R[:lstat], 5)), data: :Boston)

    expect((fit.coefficients[[1]] >> 0)).to be_within(1e-8).of(22.53280632411)
    expect((fit.coefficients[[2]] >> 0)).to be_within(1e-8).of(-152.4595487225)
    expect((fit.coefficients[[4]] >> 0)).to be_within(1e-8).of(-27.0510978864097)
    expect((fit.coefficients[[6]] >> 0)).to be_within(1e-8).of(-19.2524177100554)
  end
end
