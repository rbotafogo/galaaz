# frozen_string_literal: true

require 'galaaz'
require 'tmpdir'

describe 'Arrow semantics' do
  before(:all) do
    ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE)")
    skip 'R package arrow is not available' unless ok == true
  end

  it 'creates an Arrow table from a data.frame via Ruby helper' do
    df = R.data__frame(x: (1..3), y: (3..1))
    tbl = R::Arrow.table_from(df)
    expect(tbl.rclass.split(' ')).to include('Table')
  end

  it 'writes and reads Feather through namespaced Arrow helpers' do
    path = File.join(Dir.tmpdir, 'galaaz_arrow_semantics.feather')
    df1 = R.data__frame(x: (1..5), y: (~:letters)[(1..5)])

    R::Arrow.write_feather(df1, path)
    df2 = R::Arrow.read_feather(path)

    expect(df2.names).to eq R.c('x', 'y')
    expect(df2.nrow >> 0).to eq 5
    expect(df2.rclass.split(' ')).to include('tbl_df').or include('data.frame')
    expect(df2[[1]][1]).to eq 1
    expect(df2[[1]][5]).to eq 5
    expect(df2[[2]][1]).to eq 'a'
    expect(df2[[2]][5]).to eq 'e'
  end

  it 'opens Parquet dataset and runs grouped aggregation with dplyr' do
    path = File.join(Dir.tmpdir, 'galaaz_arrow_semantics.parquet')
    R.install_and_loads('dplyr', 'arrow')

    df = R.data__frame(group: R.c('a', 'a', 'b', 'b'), value: R.c(1, 2, 3, 4))
    R::Arrow.write_parquet(df, path)

    ds = R::Arrow.dataset(path)
    grouped = R.dplyr___group_by(ds, :group)
    summarised = R.dplyr___summarise(grouped, total: E.sum(:value))
    collected = R.dplyr___collect(summarised)

    expect(collected.rclass.split(' ')).to include('tbl_df').or include('data.frame')
    expect(collected.nrow >> 0).to eq 2

    groups = collected[['group']]
    totals = collected[['total']]
    rows = {}
    (1..(groups.length >> 0)).each do |i|
      grp = groups[i]
      tot = totals[i]
      grp = grp.to_ruby if grp.respond_to?(:to_ruby)
      tot = tot.to_ruby if tot.respond_to?(:to_ruby)
      grp = grp.first if grp.is_a?(Array)
      tot = tot.first if tot.is_a?(Array)
      rows[grp] = tot
    end
    expect(rows['a']).to eq 3
    expect(rows['b']).to eq 7
  end
end
