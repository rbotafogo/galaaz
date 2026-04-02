# frozen_string_literal: true

require 'galaaz'

describe 'R.batch (Phase 4 — fail-fast multi-op bridge)' do
  it 'returns one legacy envelope per op when all succeed' do
    a = R::Support.generate_var_name
    b = R::Support.generate_var_name
    c = R::Support.generate_var_name

    res = R.batch do |batch|
      batch.eval_with_result("#{a} <- 10L")
      batch.eval_with_result("#{b} <- #{a} + 5L")
      batch.eval_with_result("#{c} <- #{b} * 2L")
    end

    expect(res.size).to eq(3)
    expect(res[0][:type]).to eq(:scalar_integer)
    expect(res[0][:value]).to eq(10)
    expect(res[1][:value]).to eq(15)
    expect(res[2][:value]).to eq(30)
  end

  it 'raises BatchEvaluationError on first failing op with 0-based index' do
    v1 = R::Support.generate_var_name
    v3 = R::Support.generate_var_name

    err = nil
    expect do
      R.batch do |batch|
        batch.eval_with_result("#{v1} <- 1L")
        batch.eval_with_result("stop('galaaz_batch_intentional_failure')")
        batch.eval_with_result("#{v3} <- 99L")
      end
    end.to raise_error(R::BatchEvaluationError) { |e| err = e }

    expect(err.failed_index).to eq(1)
    expect(R::Support.eval(v1)).to eq(1)
    expect { R::Support.eval(v3) }.to raise_error(NewBridge::SessionClient::RProcessError, /not found/i)
  end

  it 'rejects empty batch' do
    expect do
      R.batch { |_b| }
    end.to raise_error(ArgumentError, /at least one/)
  end
end
