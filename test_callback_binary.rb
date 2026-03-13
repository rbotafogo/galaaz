#!/usr/bin/env ruby
# Minimal test: callback that calls back into R using binary protocol

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'galaaz'

puts "Test 1: Simple callback (no binary protocol)"
simple_cb = Proc.new { 42 }
R.call_me <- function(f) { f() }
result = R.call_me(simple_cb)
puts "Result: #{result.to_s}"
puts "PASSED: Simple callback works"

puts "\nTest 2: Callback that accesses R data (uses binary protocol)"
access_cb = Proc.new do |r_list|
  # This triggers the binary protocol in the callback
  puts "R list class: #{r_list.class}"
  puts "R list length: #{r_list.length}"  # This calls eval_r_with_result in callback
  "done"
end

R.test_list <- list(a = 1, b = 2, c = 3)
begin
  result = R.call_me(access_cb, R.test_list)
  puts "Result: #{result.to_s}"
  puts "PASSED: Binary protocol in callback works"
rescue => e
  puts "FAILED: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

puts "\nTest 3: Multiple nested calls (like gknit does)"
nested_cb = Proc.new do |opts|
  puts "Accessing field..."
  # This is what knitr does - access fields on R objects
  val = opts.length rescue "error: #{$!}"
  puts "Length: #{val}"
  
  val2 = opts.names rescue "error: #{$!}"
  puts "Names: #{val2}"
  
  "done"
end

R.test_opts <- list(fig.keep = "high", dev = "png")
begin
  result = R.call_me(nested_cb, R.test_opts)
  puts "Result: #{result.to_s}"
  puts "PASSED: Nested field access works"
rescue => e
  puts "FAILED: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

R.bridge.close
puts "\nAll tests completed."
