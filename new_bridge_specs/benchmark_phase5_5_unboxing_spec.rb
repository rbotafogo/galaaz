# frozen_string_literal: true

# Benchmark-only spec for Phase 5.5 deep unboxing performance.
# Run:
# bin/run_rspec specs/new_bridge/benchmark_phase5_5_unboxing_spec.rb --format documentation
#
# Optional env:
#   BENCH_ITERS=5               # default: 5
#   BENCH_TARGET_DEPTH=100      # default: 100 (nested list depth)


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.5 benchmark deep unboxing (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new bridge (avoid GALAAZ_BRIDGE_IMPL=shadow)' if R.shadow_bridge_selected?
  end

  def measure_seconds
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  end

  def stats(arr)
    return { avg: 0.0, min: 0.0, max: 0.0 } if arr.empty?

    {
      avg: arr.sum / arr.size.to_f,
      min: arr.min,
      max: arr.max
    }
  end

  it 'benchmarks unpack time for a nested list of depth 100' do
    bridge = R.bridge
    expect(bridge).to respond_to(:unbox_walk)
    expect(bridge).to respond_to(:unbox_materialize)

    iters = (ENV['BENCH_ITERS'] || '5').to_i
    target_depth = (ENV['BENCH_TARGET_DEPTH'] || '100').to_i

    deep = nil
    build_s = measure_seconds do
      deep = R.list(1)
      target_depth.times { deep = R.list(deep) }
    end

    walk_times = []
    materialize_times = []
    unbox_times = []
    walk_statuses = []
    materialize_statuses = []
    unbox_statuses = []

    iters.times do
      walk_times << measure_seconds do
        result = bridge.unbox_walk(deep.r_interop,
                                   max_depth: R::Support::MAX_UNBOX_DEPTH,
                                   max_nodes: 300_000)
        walk_statuses << result[:status]
      end

      materialize_times << measure_seconds do
        result = bridge.unbox_materialize(deep.r_interop,
                                          max_depth: R::Support::MAX_UNBOX_DEPTH,
                                          max_nodes: 300_000)
        materialize_statuses << result[:status]
      end

      unbox_times << measure_seconds do
        begin
          deep >> nil
          unbox_statuses << :ok
        rescue StandardError => e
          unbox_statuses << :"error:#{e.class}"
        end
      end
    end

    w = stats(walk_times)
    m = stats(materialize_times)
    u = stats(unbox_times)

    puts "\n[BENCH] nested-depth benchmark"
    puts "[BENCH] target_depth=#{target_depth} max_unbox_depth=#{R::Support::MAX_UNBOX_DEPTH} iters=#{iters}"
    puts format('[BENCH] build_once      %.3fs', build_s)
    puts format('[BENCH] unbox_walk     avg=%.3fs min=%.3fs max=%.3fs statuses=%s',
                w[:avg], w[:min], w[:max], walk_statuses.inspect)
    puts format('[BENCH] materialize    avg=%.3fs min=%.3fs max=%.3fs statuses=%s',
                m[:avg], m[:min], m[:max], materialize_statuses.inspect)
    puts format('[BENCH] deep >> nil    avg=%.3fs min=%.3fs max=%.3fs statuses=%s',
                u[:avg], u[:min], u[:max], unbox_statuses.inspect)
  end
end

