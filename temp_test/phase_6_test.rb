# phase_6_test.rb
$LOAD_PATH.unshift File.expand_path('desenv_linux/galaaz/lib', __dir__)
require 'galaaz'

puts "--- Phase 6: Implicit Chunking Test ---"

# Set a small CHUNK_SIZE for testing purposes
R::Vector.send(:remove_const, :CHUNK_SIZE)
R::Vector.const_set(:CHUNK_SIZE, 500_000)

begin
  # 1. Create a large vector (2.5 million elements)
  # R.seq(1, 2500000)
  puts "\nCreating a 2.5M element vector in R..."
  vec = R.seq(1, 2_500_000)
  puts "Vector handle: #{vec.r_interop}, length: #{vec.length >> 0}"

  # 2. Test map with chunking
  puts "Applying map { |x| x * 2 } (should trigger 5 chunks of 500k each)..."
  start_time = Time.now
  res = vec.map { |x| x * 2 }
  end_time = Time.now
  puts "Map completed in #{end_time - start_time} seconds."

  # 3. Verify results at different positions
  puts "\nVerifying results..."
  
  # First element (Chunk 1)
  v1 = res >> 0
  puts "res[0] = #{v1} (Expected: 2.0)"
  
  # Middle element (Chunk 3)
  v_mid = res >> 1_250_000
  puts "res[1250000] = #{v_mid} (Expected: 2500002.0)"
  
  # Last element (Chunk 5)
  v_last = res >> 2_499_999
  puts "res[2499999] = #{v_last} (Expected: 5000000.0)"

  if v1 == 2.0 && v_mid == 2_500_002.0 && v_last == 5_000_000.0
    puts "\nSUCCESS: Implicit chunking is FUNCTIONAL!"
  else
    puts "\nFAILURE: Result mismatch."
  end

ensure
  R.bridge.close if R.respond_to?(:bridge)
end
