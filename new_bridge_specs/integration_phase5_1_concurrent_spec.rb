# frozen_string_literal: true

# Phase 5.1 concurrent semantics on the R.bridge seam.
# Run:
# bin/run_rspec specs/new_bridge/integration_phase5_1_concurrent_spec.rb


require_relative '../lib/R_interface/r'

RSpec.describe 'Phase 5.1 integration concurrent (R.bridge seam)' do
  it 'serializes concurrent eval_r_with_result calls and returns correct results' do
    bridge = R.bridge
    n_threads = 5
    rounds_per_thread = 10
    results_mutex = Mutex.new
    results = []
    errors = []

    threads = n_threads.times.map do |thread_id|
      Thread.new do
        rounds_per_thread.times do |round|
          expected_value = (thread_id * 1000) + round
          assignment = "g2_v_t#{thread_id}_r#{round} <- #{expected_value}L"
          env = bridge.eval_r_with_result(assignment)
          results_mutex.synchronize do
            if env && env[:type] == :scalar_integer && env[:value] == expected_value
              results << { thread_id: thread_id, round: round, value: env[:value] }
            else
              errors << { thread_id: thread_id, round: round, env: env, expected: expected_value }
            end
          end
        end
      end
    end

    threads.each(&:join)

    expect(errors).to eq([])
    expect(results.size).to eq(n_threads * rounds_per_thread)

    seen = {}
    results.each do |r|
      key = [r[:thread_id], r[:round]]
      expect(seen[key]).to be_nil
      seen[key] = true
      expect(r[:value]).to eq((r[:thread_id] * 1000) + r[:round])
    end
  end
end

