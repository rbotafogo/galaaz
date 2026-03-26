# frozen_string_literal: true

# Phase 5.4 concurrent session routing integration on the R.bridge seam.
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_4_concurrent_sessions_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../../lib/R_interface/r'

RSpec.describe 'Phase 5.4 integration concurrent sessions (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new_bridge seam' unless ENV['GALAAZ_BRIDGE_IMPL'] == 'new_bridge'
  end

  it 'isolates writes and reads per session under concurrency' do
    bridge = R.bridge
    expect(bridge).to respond_to(:with_session)

    n_threads = 6
    rounds = 8
    values = Queue.new
    errors = Queue.new

    threads = n_threads.times.map do |tid|
      Thread.new do
        session = "sess-#{tid}"
        rounds.times do |r|
          expected = (tid * 100) + r
          begin
            got = bridge.with_session(session) do
              bridge.eval_r_with_result("g2_v_slot <- #{expected}L")
              bridge.eval_r_with_result('g2_v_read <- g2_v_slot')[:value]
            end
            values << [session, r, got, expected]
          rescue => e
            errors << [session, r, e.class.name, e.message]
          end
        end
      end
    end

    threads.each(&:join)

    expect(errors.size).to eq(0), "errors: #{errors.size}"
    expect(values.size).to eq(n_threads * rounds)

    until values.empty?
      _session, _r, got, expected = values.pop(true) rescue break
      expect(got).to eq(expected)
    end
  end
end

