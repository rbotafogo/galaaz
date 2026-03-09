
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'R_interface/r'

puts "Testing Galaaz 2.0 Callbacks..."

# Define a Ruby callback
my_ruby_proc = Proc.new do
  puts "JRuby: Callback reached!"
  42.0
end

# In R, we'll use 'lapply' or a simple call to trigger the callback
# parse_arg will wrap my_ruby_proc in an R function
begin
  # A better way: define a helper in R that calls its argument
  puts "Defining R helper function 'call_me'..."
  R.bridge.eval_r("call_me <- function(f) { f() }")
  
  puts "Calling R 'call_me' with Ruby Proc..."
  # R.call_me will trigger method_missing -> process_missing -> exec_function
  # which will then call call_me(wrapper_function)
  result = R.call_me(my_ruby_proc)
  
  puts "Handle from R: #{result.r_interop}"
  puts "String representation from R: #{result.to_s}"
  
  unboxed = result >> nil
  puts "Unboxed result from R: #{unboxed.inspect}"
  
  if unboxed == 42.0 || unboxed == 42
    puts "SUCCESS: Callback worked!"
  else
    puts "FAILURE: Unexpected unboxed result: #{unboxed.inspect}"
  end

rescue => e
  puts "Error during callback test: #{e.message}"
  puts e.backtrace.join("\n")
ensure
  R.bridge.close
end
