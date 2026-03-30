# frozen_string_literal: true

require 'galaaz'
require 'tmpdir'

describe 'Unboxing recursion regression' do
  it 'unboxes Arrow/dplyr collected scalar views without stack overflow' do
    ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE) && requireNamespace('dplyr', quietly=TRUE)")
    skip 'arrow/dplyr not available' unless ok == true

    path = File.join(Dir.tmpdir, 'galaaz_unboxing_recursion.parquet')
    df = R.data__frame(group: R.c('a', 'a', 'b', 'b'), value: R.c(1, 2, 3, 4))
    R::Arrow.write_parquet(df, path)

    ds = R::Arrow.dataset(path)
    grouped = R.dplyr___group_by(ds, :group)
    summarised = R.dplyr___summarise(grouped, total: E.sum(:value))
    collected = R.dplyr___collect(summarised)

    # These are scalar views represented as one-column data.frame handles in this path.
    total_cell = collected[[1, 'total']]
    group_cell = collected[[1, 'group']]
    expect(total_cell).to be_a(R::DataFrame)
    expect(group_cell).to be_a(R::DataFrame)

    # Regression target: this used to recurse until stack overflow.
    expect(total_cell >> 0).to eq 3
    expect(group_cell >> 0).to eq 'a'
  end
end
