# frozen_string_literal: true

# Multithreaded Ruby → single R workflow
#
# Pattern: JRuby runs several threads (e.g. one connection per shard). Each thread
# performs I/O-bound work (here simulated; replace with Sequel/SQLite/pg per shard).
# Results are merged in Ruby, then passed to R in one or a few bridge calls for
# analytics (dplyr on an Arrow table, or a plain data.frame).
#
# Run from repo root (JRuby + R as for other examples):
#   jruby examples/multithread_shards_to_r/shards_to_r.rb
#
# See also:
#   specs/bridge_concurrent_spec.rb — many threads calling R; bridge serializes.
#   specs/arrow_from_ruby_batches_spec.rb — same merge → R pattern with Arrow.

require 'galaaz'

SHARD_COUNT = 3
ROWS_PER_SHARD = 200

# Replace this with a real query, e.g.:
#   Sequel.connect(ENV.fetch("DATABASE_URL_SHARD_#{shard_id}"))
#     .fetch("SELECT id, region, amount FROM events WHERE shard_id = ?", shard_id)
#     .map { |r| r.symbolize_keys }
def fetch_rows_from_shard(shard_id)
  base = shard_id * ROWS_PER_SHARD
  (0...ROWS_PER_SHARD).map do |j|
    n = base + j
    {
      shard: shard_id,
      id: n,
      region: "r#{n % 4}",
      amount: (n % 17) + 1.0
    }
  end
end

batches = []
batch_mx = Mutex.new

threads = SHARD_COUNT.times.map do |sid|
  Thread.new do
    rows = fetch_rows_from_shard(sid)
    batch_mx.synchronize { batches << rows }
  end
end
threads.each(&:join)

merged = batches.flatten
puts "Collected #{merged.size} rows from #{SHARD_COUNT} threads in Ruby"

unless R::Support.eval("requireNamespace('arrow', quietly=TRUE) && requireNamespace('dplyr', quietly=TRUE)") == true
  warn 'Skipping R aggregation: install R packages arrow and dplyr, or use R.data__frame from merged hashes.'
  exit 0
end

tbl = R::Arrow.from_ruby_batches(merged)
grouped = R.dplyr___group_by(tbl, :region)
summarised = R.dplyr___summarise(
  grouped,
  n: E.n,
  total: E.sum(:amount),
  mean_amt: E.mean(:amount)
)
out = R.dplyr___collect(summarised)
puts R.as__data__frame(out)
