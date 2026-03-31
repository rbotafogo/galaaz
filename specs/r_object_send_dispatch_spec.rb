# frozen_string_literal: true

require 'galaaz'

describe 'R::Object send dispatch' do
  it 'uses Ruby send instead of R send(...) function call' do
    df = R.data__frame(mpg: R.c(21, 22), cyl: R.c(6, 4))
    mpg = df.send(:mpg)

    expect(mpg).to be_a(R::Object)
    expect(mpg.unboxed_get(0)).to eq(21)
  end
end
