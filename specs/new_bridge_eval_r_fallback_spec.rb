require 'galaaz'

describe R::NewBridgeAdapter do
  let(:bridge) { R.bridge }
  let(:client) { bridge.instance_variable_get(:@client) }

  it 'retries in side-effect mode for exact phase1 scalar limitation error' do
    calls = []
    err = NewBridge::SessionClient::RProcessError.new('phase1 requires length-1 scalar')

    allow(client).to receive(:eval_r).and_wrap_original do |_m, code, **kwargs|
      calls << [code, kwargs]
      if calls.length == 1
        raise err
      else
        { 'kind' => 'integer', 'value' => 0 }
      end
    end

    result = bridge.eval_r('function(x) { x }')

    expect(result).to eq('')
    expect(calls.length).to eq(2)
    expect(calls[1][0]).to eq('({ function(x) { x }; 0L })')
  end

  it 'retries in side-effect mode for exact unsupported type error' do
    calls = []
    err = NewBridge::SessionClient::RProcessError.new('unsupported type')

    allow(client).to receive(:eval_r).and_wrap_original do |_m, code, **kwargs|
      calls << [code, kwargs]
      if calls.length == 1
        raise err
      else
        { 'kind' => 'integer', 'value' => 0 }
      end
    end

    result = bridge.eval_r('x <- c(1,2,3)')

    expect(result).to eq('')
    expect(calls.length).to eq(2)
    expect(calls[1][0]).to eq('({ x <- c(1,2,3); 0L })')
  end

  it 'does not swallow unrelated RProcessError even with similar words' do
    err = NewBridge::SessionClient::RProcessError.new('Error: unrelated unsupported type mismatch on user code')
    allow(client).to receive(:eval_r).and_raise(err)

    expect do
      bridge.eval_r('stop("boom")')
    end.to raise_error(NewBridge::SessionClient::RProcessError, /unrelated unsupported type mismatch/)
  end
end
