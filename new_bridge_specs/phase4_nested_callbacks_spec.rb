# frozen_string_literal: true

# Phase 4: Nested Ruby->R during R callback waits.
# Run: bundle exec rspec specs/new_bridge/phase4_nested_callbacks_spec.rb

root = File.expand_path('../..', __dir__)
$LOAD_PATH.unshift(File.join(root, 'lib')) unless $LOAD_PATH.include?(File.join(root, 'lib'))

require 'new_bridge'

RSpec.describe 'NewBridge Phase 4 (Nested callbacks)' do
  let(:phase1_cpp) { File.expand_path('../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__) }

  before(:all) do
    skip 'R not on PATH' unless system('command -v R >/dev/null 2>&1')
    cpp = File.expand_path('../ext/new_bridge/galaaz_gatekeeper_phase1.cpp', __dir__)
    @client = NewBridge::SessionClient.new(source_path: cpp)
    @client.start
  end

  after(:all) do
    @client&.stop
  end

  def with_client
    yield @client
  end

  it 'deep recursion: Ruby callback calls back into R and returns correct value' do
    with_client do |c|
      # Register callback that does nested eval_r into R
      cb_call_id = c.register_callback do |_payload, call_id|
        # Nested call into R - this tests the core Phase 4 scenario
        nested_result = c.eval_r('41L + 1L', parent_id: call_id)
        nested_result['value']  # Return 42
      end

      # R calls the callback via galaaz_callback_call_phase3
      out = c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', 'unused', 5000)")

      expect(out['kind']).to eq('double')
      expect(out['value']).to eq(42)
    end
  end

  it 'error unwinding: Ruby callback raises, error propagates correctly' do
    with_client do |c|
      cb_call_id = c.register_callback do |_payload, _call_id|
        raise 'callback error from Ruby'
      end

      # Note: Error message is generic because R_tryEval catches Rcpp::stop
      # The important thing is that an error is raised, not the specific message
      expect do
        c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', 'unused', 5000)")
      end.to raise_error(NewBridge::SessionClient::RProcessError)
    end
  end

  it 'timeout: Ruby callback sleeps too long, raises timeout' do
    with_client do |c|
      cb_call_id = c.register_callback do |_payload, _call_id|
        sleep 0.5  # Sleep longer than callback timeout
        999
      end

      # The callback times out after 50ms, but the Ruby sleep is 500ms
      # Note: Error message is generic because R_tryEval catches Rcpp::stop
      expect do
        c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', 'unused', 50)", timeout: 2)
      end.to raise_error(NewBridge::SessionClient::RProcessError)
    end
  end

  it 'nested ordering: multiple nested calls complete correctly' do
    with_client do |c|
      call_count = 0

      cb_call_id = c.register_callback do |_payload, call_id|
        call_count += 1
        # Multiple nested calls
        r1 = c.eval_r('10L + 1L', parent_id: call_id)
        r2 = c.eval_r('20L + 2L', parent_id: call_id)
        r3 = c.eval_r('30L + 3L', parent_id: call_id)

        r1['value'] + r2['value'] + r3['value']  # 11 + 22 + 33 = 66
      end

      out = c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', 'unused', 5000)")

      expect(out['value']).to eq(66)
      expect(call_count).to eq(1)
    end
  end

  # dplyr/rlang fancy errors can lose their causal message under nested callback
  # stacks (path_trim_prefix/strsplit). Gatekeeper wraps nested evals so Ruby
  # still sees "object 'a' not found".
  it 'preserves causal dplyr error messages under nested eval', :slow do
    with_client do |c|
      probe = c.eval_r("isTRUE(requireNamespace('dplyr', quietly = TRUE))")
      skip 'dplyr not installed' unless probe['value'] == true

      nested_msg = nil
      cb_call_id = c.register_callback do |_payload, call_id|
        begin
          c.eval_r(
            "__G_EVAL_WITH_RESULT__tmp <- { library(dplyr); mutate(data.frame(x = 1:3), y = a + x) }",
            parent_id: call_id
          )
        rescue NewBridge::SessionClient::RProcessError => e
          nested_msg = e.message.to_s
        end
        1.0
      end

      c.eval_r("galaaz_callback_call_phase3('#{cb_call_id}', 'unused', 15000)", timeout: 30)

      expect(nested_msg).to match(/object 'a' not found/)
      expect(nested_msg).not_to match(/strsplit|path_trim_prefix/)
    end
  end
end
