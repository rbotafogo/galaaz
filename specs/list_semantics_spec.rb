# frozen_string_literal: true

require 'galaaz'

describe R::List do
  context 'creation and unboxing' do
    it 'creates empty and populated lists' do
      empty = R.list
      expect(empty.length).to eq 0
      expect(empty).to be_a(R::List)

      l = R.list(1, a: 2, b: 3, c: R.list(4, 5, 6))
      expect(l.length).to eq 4
      expect(l >> 0).to eq 1
      expect(l >> 3).to eq [4, 5, 6]
      expect(l['k'] >> 0).to eq nil
    end
  end

  context "subsetting with '[' and '[['" do
    before(:each) do
      @l = R.list(a: 1, b: 2, all: 3, d: R.list(i: 4, j: 5, all: 6))
    end

    it 'returns a list when using []' do
      expect(@l[1]).to eq R.list(a: 1)
      expect(@l[R.c(4, 1)] == R.list(d: R.list(i: 4, j: 5, all: 6), a: 1)).to eq true
    end

    it 'raises bridge process error when [] receives wrong index dimension' do
      expect { @l[4, 1] }.to raise_error(NewBridge::SessionClient::RProcessError)
    end

    it 'returns elements when using [[]]' do
      raw = R.list(1, 2, 3, R.list(4, 5, 6))
      expect(raw[[1]]).to eq 1
      expect(raw[[4]].identical(R.list(4, 5, 6))).to eq true
      expect(raw[[R.c(4, 1)]]).to eq 4
    end
  end

  context 'named access and assignment' do
    before(:each) do
      @l = R.list(a: 1, b: 2, c: 3, d: R.list(i: 4, j: 5, k: 6))
    end

    it 'supports dot access for named elements' do
      expect(@l.a).to eq 1
      expect(@l.d.identical(R.list(i: 4, j: 5, k: 6))).to eq true
    end

    it 'supports setting and removing named elements' do
      @l[['a']] = 10
      @l.b = 20
      @l.married = true
      expect(@l[['a']]).to eq 10
      expect(@l.b).to eq 20
      expect(@l.married).to eq true

      @l.d = nil
      expect(@l.length).to eq 4
      expect(@l[['d']]).to eq nil
    end
  end
end
