# frozen_string_literal: true

# Async synchronization for Stage B1 Arrow IPC handoff.
# Run: bin/run_all_rspec new_bridge_specs/arrow_ipc_async_spec.rb

require 'thread'
require 'galaaz'

RSpec.describe 'Arrow IPC async handoff' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
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

  it 'happens-before: write+fsync then async open returns correct nrow' do
    values = [1.0, 2.0, 3.0, 4.0]
    path = track(Galaaz::ArrowIpc.write(value: values))

    done = Queue.new
    # Path-only over the bridge; R reads the IPC file.
    R.eval_r_async("nrow(arrow::read_ipc_file(#{path.inspect}))", timeout: 30) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).to be_ok
    expect(r.value).to match(/4/)
  end

  it 'async open then sync R reduction on the proxy' do
    path = track(Galaaz::ArrowIpc.write(value: [10.0, 20.0, 30.0]))

    done = Queue.new
    R::Async.arrow___read_ipc_file(path, as_data_frame: false, timeout: 30) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).to be_ok
    expect(r.value).to be_a(R::Object)

    tbl = r.value
    mean = R.mean(R.dplyr___pull(tbl, :value))
    mean_v = mean.respond_to?(:>>) ? (mean >> 0) : mean
    expect(mean_v).to eq(20.0)
  end

  it 'two concurrent handoffs do not cross-talk' do
    path_a = track(Galaaz::ArrowIpc.write(tag: ['A'], n: [1]))
    path_b = track(Galaaz::ArrowIpc.write(tag: ['B', 'B'], n: [2, 2]))

    done = Queue.new
    R.eval_r_async("nrow(arrow::read_ipc_file(#{path_a.inspect}))", timeout: 30) do |result|
      done.push([:a, result])
    end
    R.eval_r_async("nrow(arrow::read_ipc_file(#{path_b.inspect}))", timeout: 30) do |result|
      done.push([:b, result])
    end

    results = {}
    2.times do
      key, res = done.pop
      expect(res).to be_ok
      results[key] = res.value
    end
    expect(results[:a]).to match(/1/)
    expect(results[:b]).to match(/2/)
  end

  it 'missing path fails without hanging' do
    done = Queue.new
    missing = File.join(Galaaz::ArrowIpc.scratch_dir, 'galaaz_missing_async.arrow')
    R.eval_r_async("arrow::read_ipc_file(#{missing.inspect})", timeout: 10) do |result|
      done.push(result)
    end
    r = done.pop
    expect(r).not_to be_ok
  end
end
