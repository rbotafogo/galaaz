#!/usr/bin/env ruby
# Minimal test for callback connection issue

require_relative 'lib/galaaz'

puts "Testing callback connection handling..."

# Test 1: Simple callback with binary result
puts "\nTest 1: Registering a simple callback..."
callback = Proc.new do |x|
  puts "Callback received: #{x}"
  x * 2
end

# Register and call from R
R.test_callback(callback, 5)
puts "Test 1 passed"

# Test 2: Multiple calls in callback to see if connections leak
puts "\nTest 2: Multiple operations in callback..."
callback2 = Proc.new do |n|
  puts "Running #{n} operations in callback..."
  n.times do |i|
    # Each of these uses the binary protocol
    result = R.sum(c(1L, 2L, 3L))
    puts "Operation #{i}: sum = #{result}"
  end
  "done"
end

R.test_callback(callback2, 10)
puts "Test 2 passed"

# Test 3: Try to trigger the issue by accessing object fields in callback
puts "\nTest 3: Accessing object fields in callback (like .nrow on matrix)..."
callback3 = Proc.new do |df|
  puts "Received object: #{df.class}"
  puts "Type: #{df.typeof}"
  puts "Length: #{df.length}"
  # This is what triggers the bug - accessing a field like .nrow
  puts "Trying to access nrow..."
  begin
    n = df.nrow
    puts "nrow = #{n}"
  rescue => e
    puts "Error accessing nrow: #{e.message}"
  end
  "done"
end

# Create a test matrix/dataframe
R.test_matrix <- R.matrix(1:12, nrow = 3)
R.test_callback(callback3, R.test_matrix)

puts "\nAll tests completed!"
