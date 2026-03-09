# phase_7_test.rb
$LOAD_PATH.unshift File.expand_path('desenv_linux/galaaz/lib', __dir__)
require 'galaaz'

puts "--- Phase 7: Stitch Method (Contextual Overlap) Test ---"

# Set a tiny CHUNK_SIZE to force many "seams"
R::Vector.send(:remove_const, :CHUNK_SIZE)
R::Vector.const_set(:CHUNK_SIZE, 10)

begin
  # 1. Create a vector of 30 elements
  puts "\nCreating a 30-element vector (1..30)..."
  vec = R.seq(1, 30)

  # 2. Compute Moving Average (window=3) using Stitch
  # Window of 3 means we need 1 element before and 1 after (Halo=1)
  puts "Computing Moving Average (size=3) using .stitch(halo: 1)..."
  
  res = vec.stitch(halo: 1) do |data|
    # data is a Ruby Array
    # Moving average: (prev + current + next) / 3
    # For boundaries in the data array, we handle them (though stitch handles seams)
    result = []
    data.each_with_index do |val, i|
      if i == 0 || i == data.length - 1
        result << val # Keep original at the very edges of the whole vector
      else
        result << (data[i-1] + data[i] + data[i+1]) / 3.0
      end
    end
    result
  end

  # 3. Verify results
  puts "\nVerifying results..."
  
  # Seam 1: Index 9 (end of chunk 1) and Index 10 (start of chunk 2)
  v9 = res >> 9
  v10 = res >> 10
  
  # Manual calculation for index 9 (values are 1-based: 9, 10, 11)
  # (9 + 10 + 11) / 3 = 10.0
  puts "res[9] = #{v9} (Expected: 10.0)"
  
  # Manual calculation for index 10 (values: 10, 11, 12)
  # (10 + 11 + 12) / 3 = 11.0
  puts "res[10] = #{v10} (Expected: 11.0)"

  if (v9 - 10.0).abs < 0.001 && (v10 - 11.0).abs < 0.001
    puts "\nSUCCESS: Stitch method handles contextual overlap correctly!"
  else
    puts "\nFAILURE: Seam calculation mismatch."
  end

ensure
  R.bridge.close if R.respond_to?(:bridge)
end
