# frozen_string_literal: true

# Phase 5.5 stress-level concurrency integration on the R.bridge seam.
# Run:
#   GALAAZ_BRIDGE_IMPL=new_bridge bin/run_rspec specs/new_bridge/integration_phase5_5_stress_concurrency_spec.rb

ENV['GALAAZ_BRIDGE_IMPL'] ||= 'new_bridge'

require_relative '../../lib/R_interface/r'

RSpec.describe 'Phase 5.5 integration stress concurrency (R.bridge seam)' do
  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    skip 'requires new_bridge seam' unless ENV['GALAAZ_BRIDGE_IMPL'] == 'new_bridge'
  end

  it 'maintains session isolation under higher concurrent load' do
    bridge = R.bridge
    expect(bridge).to respond_to(:with_session)

    n_threads = 12
    rounds = 20
    errors = Queue.new
    ok_count = Queue.new

    threads = n_threads.times.map do |tid|
      Thread.new do
        session = "stress-sess-#{tid}"
        rounds.times do |r|
          expected = (tid * 10_000) + r
          begin
            got = bridge.with_session(session) do
              bridge.eval_r_with_result("g2_v_stress <- #{expected}L")
              bridge.eval_r_with_result('g2_v_read <- g2_v_stress')[:value]
            end
            if got == expected
              ok_count << true
            else
              errors << [session, r, :mismatch, got, expected]
            end
          rescue => e
            errors << [session, r, e.class.name, e.message]
          end
        end
      end
    end

    threads.each(&:join)

    expect(errors.size).to eq(0), "errors=#{errors.size}"
    expect(ok_count.size).to eq(n_threads * rounds)
  end
end

