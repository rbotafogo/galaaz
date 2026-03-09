# verify_galaaz_2_0.rb
$LOAD_PATH.unshift File.expand_path('desenv_linux/galaaz/lib', __dir__)
require 'galaaz'

puts "--- Galaaz 2.0 Integration Test ---"

begin
  # 1. Create a vector using R.c
  puts "Ruby: Creating vector vec = R.c(10.5, 20.5, 30.5)"
  vec = R.c(10.5, 20.5, 30.5)
  puts "Ruby: Got object of class #{vec.class} with handle #{vec.r_interop}"

  # 2. Unbox an element
  puts "Ruby: Unboxing element 1 (should be 20.5)..."
  val = vec >> 1
  puts "Ruby: Result is #{val}"

  # 3. Shadow Vector Map
  puts "Ruby: Testing vec.map { |x| x + 1.0 }"
  vec2 = vec.map { |x| x + 1.0 }
  puts "Ruby: Got vec2 of class #{vec2.class} with handle #{vec2.r_interop}"
  
  val2 = vec2 >> 1
  puts "Ruby: Result of vec2[1] is #{val2} (should be 21.5)"

  # 4. DataFrame Transport (Feather)
  puts "Ruby: Testing DataFrame transport with 'mtcars'"
  df = R.mtcars
  puts "Ruby: Got df of class #{df.class} with handle #{df.r_interop}"
  
  feather_path = R.bridge.pull_dataframe(df.r_interop)
  puts "Ruby: DataFrame exported to Feather at #{feather_path}"
  
  if File.exist?(feather_path) && File.size(feather_path) > 0
    puts "SUCCESS: DataFrame Feather export is FUNCTIONAL!"
  else
    puts "FAILURE: DataFrame Feather export failed."
  end

  # 5. DataFrame Field Access
  puts "Ruby: Testing df.mpg"
  mpg = df.mpg
  puts "Ruby: Got mpg of class #{mpg.class} with handle #{mpg.r_interop}"
  puts "Ruby: mpg[0] is #{mpg >> 0} (should be 21.0)"
  
  if ((mpg >> 0) - 21.0).abs < 0.001
    puts "SUCCESS: DataFrame Field Access is FUNCTIONAL!"
  else
    puts "FAILURE: DataFrame Field Access mismatch."
  end

rescue Exception => e
  puts "ERROR: #{e.message}"
  puts e.backtrace
ensure
  R.bridge.close if R.respond_to?(:bridge)
end
