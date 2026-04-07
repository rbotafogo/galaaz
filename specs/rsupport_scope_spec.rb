# frozen_string_literal: true

require 'galaaz'

describe R::Support do
  describe '.new_scope' do
    it 'evaluates expression-style calls inside dataframe scope' do
      df = R.data__frame(a: (1..4), b: R.c(10, 20, 30, 40))

      out = R::Support.new_scope(:with, df) do
        (a > 2).eval(df)
      end

      expect(out).to eq R.c(false, false, true, true)
    end

    it 'allows direct column access via generated methods' do
      df = R.data__frame(a: (1..3), b: R.c(5, 6, 7))

      val = R::Support.new_scope(:with, df) do
        (a + b).eval(df)
      end

      expect(val).to eq R.c(6, 8, 10)
    end
  end
end

