# frozen_string_literal: true

# Run a galaaz DESeq2 airway example three times in one JRuby process (warm-up semantics).
#
# Usage (from repository root):
#   bin/galaaz-jruby examples/bioconductor_deseq2_airway/bench_galaaz_three_same_process.rb
#   bin/galaaz-jruby examples/bioconductor_deseq2_airway/bench_galaaz_three_same_process.rb optimized
#   bin/galaaz-jruby examples/bioconductor_deseq2_airway/bench_galaaz_three_same_process.rb original

require 'galaaz'

using Galaaz::SymbolDSL
root = File.expand_path('../..', __dir__)
Dir.chdir(root)

variant = (ARGV[0] || 'optimized').downcase
script = case variant
         when 'original'
           'deseq2_airway_galaaz.rb'
         when 'optimized'
           'deseq2_airway_galaaz_optimized.rb'
         else
           warn "Unknown variant #{variant.inspect}; use 'optimized' or 'original'"
           exit 1
         end

path = File.expand_path(script, __dir__)

unless File.file?(path)
  warn "Missing #{path}"
  exit 1
end

puts "=== galaaz (#{variant}): three runs, same process (root: #{root})"
times = []
3.times do |i|
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  load path
  t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  sec = t1 - t0
  times << sec
  puts format('galaaz run %d/3: %.2f s', i + 1, sec)
end

warm = times[1..2]
ws = warm.sort
warm_median = (ws[0] + ws[1]) / 2.0
all_sorted = times.sort
all_median = all_sorted[1]

puts '---'
puts format('Warm median (runs 2–3): %.2f s', warm_median)
puts format('Warm mean (runs 2–3):   %.2f s', warm.sum / warm.size)
puts format('All-run median:           %.2f s', all_median)
