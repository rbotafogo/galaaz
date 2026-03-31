# frozen_string_literal: true

require 'galaaz'

describe 'dispatch_probe error-class fallback' do
  it 'falls back when dispatch_probe raises bridge RProcessError' do
    ok = R::Support.eval("requireNamespace('dplyr', quietly=TRUE)")
    skip 'dplyr is not available' unless ok == true
    R.library('dplyr')

    bridge = R.bridge
    allow(bridge).to receive(:dispatch_probe).and_raise(
      NewBridge::SessionClient::RProcessError, 'invalid dispatch_probe params'
    )

    df = R.data__frame(g1: R.c('x', 'x', 'y'), a: R.c(1, 2, 3))
    out = df.group_by(:g1).summarise(a: E.mean(:a))
    expect(out.nrow >> 0).to eq(2)
  end
end
