# frozen_string_literal: true

require 'galaaz'

describe 'dispatch_probe fallback for method names' do
  it 'falls back to function dispatch when dispatch_probe rejects params' do
    ok = R::Support.eval("requireNamespace('dplyr', quietly=TRUE)")
    skip 'dplyr is not available' unless ok == true
    R.library('dplyr')

    df = R.data__frame(g1: R.c('x', 'x', 'y'), a: R.c(1, 2, 3))
    group_var = :g1

    out = df.group_by(group_var).summarise(a: E.mean(:a))
    n = out.nrow >> 0
    expect(n).to eq(2)
  end
end
