# frozen_string_literal: true

require 'galaaz'
using Galaaz::SymbolDSL

RSpec.describe 'Arrow large pipeline (slow)' do
  before(:all) do
    ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE) && requireNamespace('dplyr', quietly=TRUE)")
    skip 'R packages arrow/dplyr are not available' unless ok == true
  end

  it 'builds large Ruby batches in parallel and reduces in R' do
    thread_count = 8
    rows_per_thread = 25_000
    group_count = 10

    batches = []
    mutex = Mutex.new
    threads = []

    thread_count.times do |tid|
      threads << Thread.new do
        start = tid * rows_per_thread
        local = (start...(start + rows_per_thread)).map do |i|
          {
            id: i,
            grp: "g#{i % group_count}",
            value: (i % 17) + 1,
            weight: ((i % 5) + 1) * 0.5
          }
        end
        mutex.synchronize { batches << local }
      end
    end
    threads.each(&:join)

    total_rows = thread_count * rows_per_thread
    expected = Hash.new { |h, k| h[k] = { n: 0, total: 0, wsum: 0.0 } }
    batches.flatten.each do |r|
      e = expected[r[:grp]]
      e[:n] += 1
      e[:total] += r[:value]
      e[:wsum] += (r[:value] * r[:weight])
    end

    tbl = R::Arrow.from_ruby_batches(batches)
    expect(tbl.rclass.split(' ')).to include('Table')

    grouped = R.dplyr___group_by(tbl, R[:grp])
    summarised = R.dplyr___summarise(
      grouped,
      n: E.n(),
      total: E.sum(R[:value]),
      wsum: E.sum(R[:value] * R[:weight])
    )
    out = R.dplyr___collect(summarised)

    expect(out.nrow >> 0).to eq(group_count)

    groups = out[['grp']]
    ns = out[['n']]
    totals = out[['total']]
    wsums = out[['wsum']]

    actual = {}
    (1..(groups.length >> 0)).each do |i|
      grp = groups[i]
      n = ns[i]
      total = totals[i]
      wsum = wsums[i]

      grp = grp.respond_to?(:>>) ? (grp >> 0) : grp
      n = n.respond_to?(:>>) ? (n >> 0) : n
      total = total.respond_to?(:>>) ? (total >> 0) : total
      wsum = wsum.respond_to?(:>>) ? (wsum >> 0) : wsum

      actual[grp] = { n: n, total: total, wsum: wsum.to_f }
    end

    expect(actual.keys.sort).to eq(expected.keys.sort)
    expected.each do |grp, vals|
      got = actual[grp]
      expect(got[:n]).to eq(vals[:n])
      expect(got[:total]).to eq(vals[:total])
      expect(got[:wsum]).to be_within(1e-8).of(vals[:wsum])
    end
    expect(actual.values.sum { |v| v[:n] }).to eq(total_rows)
  end
end
