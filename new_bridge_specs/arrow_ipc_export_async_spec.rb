# frozen_string_literal: true

# Async synchronization for Stage B2 R→Ruby Arrow IPC export.
# Run: bin/run_all_rspec new_bridge_specs/arrow_ipc_export_async_spec.rb

require 'thread'
require 'galaaz'

RSpec.describe 'Arrow IPC export async (Stage B2)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'Galaaz::ArrowIpc backend not available' unless Galaaz::ArrowIpc.available?
    ok = R::Support.eval("requireNamespace('arrow', quietly=TRUE)")
    skip 'R package arrow is not available' unless ok == true
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

  it 'happens-before: async R write_ipc_file then Ruby read matches' do
    in_path = track(Galaaz::ArrowIpc.write(n: [1, 2, 3]))
    out_path = track(Galaaz::ArrowIpc.allocate_path)

    done = Queue.new
    R.eval_r_async(
      "({ arrow::write_ipc_file(arrow::read_ipc_file(#{in_path.inspect}, as_data_frame=FALSE), #{out_path.inspect}, compression='uncompressed'); 1L })",
      timeout: 30
    ) { |result| done.push(result) }
    r = done.pop
    expect(r).to be_ok

    cols = Galaaz::ArrowIpc.read(out_path)
    expect(cols['n'].map(&:to_i)).to eq([1, 2, 3])
  end

  it 'two concurrent R exports do not cross-talk' do
    in_a = track(Galaaz::ArrowIpc.write(tag: ['A']))
    in_b = track(Galaaz::ArrowIpc.write(tag: ['B']))
    out_a = track(Galaaz::ArrowIpc.allocate_path)
    out_b = track(Galaaz::ArrowIpc.allocate_path)

    done = Queue.new
    R.eval_r_async(
      "({ arrow::write_ipc_file(arrow::read_ipc_file(#{in_a.inspect}, as_data_frame=FALSE), #{out_a.inspect}, compression='uncompressed'); 1L })",
      timeout: 30
    ) { |res| done.push([:a, res]) }
    R.eval_r_async(
      "({ arrow::write_ipc_file(arrow::read_ipc_file(#{in_b.inspect}, as_data_frame=FALSE), #{out_b.inspect}, compression='uncompressed'); 1L })",
      timeout: 30
    ) { |res| done.push([:b, res]) }

    2.times do
      _key, res = done.pop
      expect(res).to be_ok
    end

    expect(Galaaz::ArrowIpc.read(out_a)['tag']).to eq(['A'])
    expect(Galaaz::ArrowIpc.read(out_b)['tag']).to eq(['B'])
  end
end
