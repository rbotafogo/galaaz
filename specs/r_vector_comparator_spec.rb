require 'galaaz'

describe R::Vector do
  it 'raises NotImplementedError for <=>' do
    vec = R.c(1, 2, 3)
    expect { vec <=> vec }.to raise_error(NotImplementedError, /not implemented/)
  end
end
