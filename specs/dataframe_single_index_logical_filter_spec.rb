# frozen_string_literal: true

require 'galaaz'

describe 'DataFrame single-index logical filtering' do
  it 'treats df[logical_expression] as row filter with all columns' do
    df = R.data__frame(
      origin: R.c('JFK', 'LGA', 'JFK'),
      month: R.c(6, 6, 7),
      value: R.c(1, 2, 3)
    )

    out = df[(R[:origin].eq('JFK')) & (R[:month].eq(6))]
    n = out.nrow >> 0
    origins = out.origin >> nil
    origins = [origins] unless origins.is_a?(Array)

    expect(n).to eq(1)
    expect(origins).to eq(['JFK'])
  end
end
