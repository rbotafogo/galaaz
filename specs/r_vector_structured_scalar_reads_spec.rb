# frozen_string_literal: true

require 'galaaz'

describe 'R::Vector structured scalar reads (result protocol)' do
  it 'unboxes indexed integer element without relying on printed length/typeof' do
    v = R.c(10, 20, 30)
    expect(v.unboxed_get(1)).to eq(20)
  end

  it 'unboxes indexed double element' do
    v = R.c(1.5, 2.5)
    expect(v.unboxed_get(0)).to eq(1.5)
  end

  it 'unboxes logical TRUE, FALSE, and NA via scalar_logical envelope' do
    v = R.c(true, false, R::NA)
    expect(v.unboxed_get(0)).to eq(true)
    expect(v.unboxed_get(1)).to eq(false)
    expect(v.unboxed_get(2)).to be_nil
  end

  it 'unboxes indexed character element' do
    v = R.c('a', 'b')
    expect(v.unboxed_get(1)).to eq('b')
  end

  it 'stitch uses protocol-based length' do
    v = R.c(1.0, 2.0, 3.0)
    out = v.stitch(halo: 0) { |chunk| chunk.map { |x| x * 2 } }
    expect(out).to be_a(R::Vector)
    expect(out.length.unboxed_get(0)).to eq(3)
    expect((out >> nil)).to eq([2.0, 4.0, 6.0])
  end
end
