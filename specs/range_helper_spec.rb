# frozen_string_literal: true

require 'galaaz'

describe 'range_helper / up_to DSL' do
  it 'supports select with symbol range syntax' do
    ok = R::Support.eval("requireNamespace('dplyr', quietly=TRUE)")
    skip 'dplyr is not available' unless ok == true

    df = R.data__frame(
      year: R.c(2020, 2021),
      month: R.c(1, 2),
      day: R.c(10, 11),
      tailnum: R.c('N1', 'N2')
    )

    out = R.dplyr___select(df, R[:year].up_to(R[:day]))
    cols = R.names(out) >> nil
    expect(cols).to eq(%w[year month day])
  end
end
