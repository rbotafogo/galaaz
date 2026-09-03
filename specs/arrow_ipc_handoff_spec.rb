# frozen_string_literal: true

require 'galaaz'

describe 'Arrow IPC handoff (Stage B1)' do
  before(:all) do
    skip 'Galaaz::ArrowIpc writer backend not available' unless Galaaz::ArrowIpc.available?
    ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE) && requireNamespace('dplyr', quietly=TRUE)")
    skip 'R packages arrow/dplyr are not available' unless ok == true
    @paths = []
  end

  after(:each) do
    Array(@paths).each { |p| Galaaz::ArrowIpc.release(p) }
    @paths = []
  end

  def track(path)
    @paths << path
    path
  end

  it 'round-trips a float64 column through open_ipc' do
    values = [1.5, 2.5, -3.0, 0.0]
    path = track(Galaaz::ArrowIpc.write(value: values))
    expect(File.exist?(path)).to be true

    tbl = R::Arrow.open_ipc(path)
    expect(tbl.rclass.split(' ')).to include('Table')
    expect((R.nrow(tbl) >> 0)).to eq(values.length)

    collected = R.dplyr___collect(tbl)
    col = collected[['value']]
    got = (1..(col.length >> 0)).map do |i|
      v = col[i]
      v.respond_to?(:>>) ? (v >> 0) : v
    end
    expect(got).to eq(values)

    Galaaz::ArrowIpc.release(path)
    expect(File.exist?(path)).to be false
  end

  it 'round-trips multi-column id/grp/value via write_batches' do
    rows = [
      { id: 1, grp: 'a', value: 10.0 },
      { id: 2, grp: 'b', value: 20.5 },
      { id: 3, grp: 'a', value: 30.0 }
    ]
    path = track(Galaaz::ArrowIpc.write_batches(rows))
    tbl = R::Arrow.open_ipc(path)

    expect((R.nrow(tbl) >> 0)).to eq(3)
    summed = R.dplyr___summarise(tbl, total: E.sum(:value))
    out = R.dplyr___collect(summed)
    total = out[['total']]
    tot = total[1]
    tot = tot.respond_to?(:>>) ? (tot >> 0) : tot
    expect(tot).to eq(60.5)
  end

  it 'raises on missing R arrow package path for open_ipc with bad path' do
    expect {
      R::Arrow.open_ipc('/tmp/galaaz_missing_ipc_file_does_not_exist.arrow')
    }.to raise_error(StandardError)
  end

  it 'raises when write is called without a usable backend message path' do
    # available? already gated the suite; still check empty columns
    expect { Galaaz::ArrowIpc.write({}) }.to raise_error(ArgumentError)
  end

  it 'optional timing smoke vs from_ruby_batches for N≈50k' do
    n = 50_000
    cols = {
      id: (0...n).to_a,
      grp: (0...n).map { |i| "g#{i % 5}" },
      value: (0...n).map { |i| (i % 10) + 1.0 }
    }

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    path = track(Galaaz::ArrowIpc.write(cols))
    tbl = R::Arrow.open_ipc(path)
    ipc_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0
    expect((R.nrow(tbl) >> 0)).to eq(n)

    rows = (0...n).map { |i| { id: i, grp: "g#{i % 5}", value: (i % 10) + 1.0 } }
    t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    tbl2 = R::Arrow.from_ruby_batches(rows)
    batch_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t1) * 1000.0
    expect((R.nrow(tbl2) >> 0)).to eq(n)

    # Not a flaky perf gate — only ensure both paths produce a table.
    expect(ipc_ms).to be > 0
    expect(batch_ms).to be > 0
  end
end
