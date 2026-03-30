# frozen_string_literal: true

require 'galaaz'

describe 'Arrow from Ruby batches' do
  before(:all) do
    ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE) && requireNamespace('dplyr', quietly=TRUE)")
    skip 'R packages arrow/dplyr are not available' unless ok == true
  end

  it 'builds Arrow table from Ruby-threaded batches and reduces in R' do
    batches = []
    mutex = Mutex.new
    threads = []

    # Simulate parallel Ruby ingestion.
    [0, 1, 2, 3].each do |tid|
      threads << Thread.new do
        start = tid * 1000
        local = (start...(start + 1000)).map do |i|
          { id: i, grp: "g#{i % 5}", value: (i % 10) + 1 }
        end
        mutex.synchronize { batches << local }
      end
    end
    threads.each(&:join)

    tbl = R::Arrow.from_ruby_batches(batches)
    expect(tbl.rclass.split(' ')).to include('Table')

    grouped = R.dplyr___group_by(tbl, :grp)
    summed = R.dplyr___summarise(grouped, total: E.sum(:value))
    out = R.dplyr___collect(summed)

    groups = out[['grp']]
    totals = out[['total']]
    result = {}
    (1..(groups.length >> 0)).each do |i|
      grp = groups[i]
      tot = totals[i]
      grp = grp.respond_to?(:>>) ? (grp >> 0) : grp
      tot = tot.respond_to?(:>>) ? (tot >> 0) : tot
      result[grp] = tot
    end

    expected = Hash.new(0)
    batches.flatten.each { |r| expected[r[:grp]] += r[:value] }
    expect(result).to eq(expected)
  end
end
