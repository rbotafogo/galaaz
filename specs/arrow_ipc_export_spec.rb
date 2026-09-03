# frozen_string_literal: true

require 'galaaz'

describe 'Arrow IPC export (Stage B2)' do
  before(:all) do
    skip 'Galaaz::ArrowIpc backend not available' unless Galaaz::ArrowIpc.available?
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

  it 'reads columns R wrote via write_ipc (R→Ruby)' do
    in_path = track(Galaaz::ArrowIpc.write(value: [1.5, 2.5], grp: %w[a b]))
    tbl = R::Arrow.open_ipc(in_path)
    out_path = track(R::Arrow.write_ipc(tbl))
    expect(File.exist?(out_path)).to be true

    cols = Galaaz::ArrowIpc.read(out_path)
    expect(cols['value']).to eq([1.5, 2.5])
    expect(cols['grp']).to eq(%w[a b])

    rows = Galaaz::ArrowIpc.read_batches(out_path)
    expect(rows).to eq([{ value: 1.5, grp: 'a' }, { value: 2.5, grp: 'b' }])
  end

  it 'proves DB-style loop: Ruby ingest → R summarise → Ruby reads result table' do
    in_path = track(Galaaz::ArrowIpc.write_batches([
      { id: 1, grp: 'a', value: 10.0 },
      { id: 2, grp: 'b', value: 20.5 },
      { id: 3, grp: 'a', value: 30.0 }
    ]))
    tbl = R::Arrow.open_ipc(in_path)
    grouped = R.dplyr___group_by(tbl, :grp)
    summed = R.dplyr___summarise(grouped, total: E.sum(:value))
    out_path = track(R::Arrow.write_ipc(summed))

    rows = Galaaz::ArrowIpc.read_batches(out_path)
    by_grp = rows.each_with_object({}) { |r, h| h[r[:grp].to_s] = r[:total].to_f }
    expect(by_grp['a']).to eq(40.0)
    expect(by_grp['b']).to eq(20.5)

    Galaaz::ArrowIpc.release(out_path)
    expect(File.exist?(out_path)).to be false
  end

  it 'raises when reading a missing IPC file' do
    expect {
      Galaaz::ArrowIpc.read('/tmp/galaaz_missing_b2.arrow')
    }.to raise_error(ArgumentError, /not found/)
  end
end
