
require 'galaaz'

# Define a Ruby function to be called from R
ruby_func = Proc.new do |x|
  puts "JRuby: Callback called with #{x.inspect}"
  (x >> 0) * 10 # Unbox x and multiply by 10
end

# Use R.lapply or similar to trigger the callback
# We need to wrap the proc so R sees it as a function
r_vec = R.c(1, 2, 3)
results = R.lapply(r_vec, ruby_func)

puts "Results from R (should be 10, 20, 30):"
puts results
