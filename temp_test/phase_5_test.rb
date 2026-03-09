# phase_5_test.rb
$LOAD_PATH.unshift File.expand_path('desenv_linux/galaaz/lib', __dir__)
require 'galaaz'

puts "--- Phase 5: Unboxing Generalization Test ---"

begin
  # 1. Vector Unboxing (Already should work)
  puts "\nTesting Vector unboxing..."
  vec = R.c(1.1, 2.2, 3.3)
  v_native = vec >> nil
  puts "Vector native: #{v_native.inspect} (Class: #{v_native.class})"
  if v_native == [1.1, 2.2, 3.3]
    puts "SUCCESS: Vector unboxing works."
  else
    puts "FAILURE: Vector unboxing failed."
  end

  # 2. Matrix Unboxing
  puts "\nTesting Matrix unboxing..."
  mat = R.matrix(R.c(1, 2, 3, 4), nrow: 2)
  begin
    m_native = mat >> nil
    puts "Matrix native: #{m_native.inspect} (Class: #{m_native.class})"
    # R matrices are column-major by default
    if m_native == [[1, 3], [2, 4]] || m_native == [1, 2, 3, 4]
      puts "SUCCESS: Matrix unboxing returned something sensible."
    else
      puts "FAILURE: Matrix unboxing returned unexpected value: #{m_native.inspect}"
    end
  rescue => e
    puts "FAILURE: Matrix unboxing raised error: #{e.message}"
  end

  # 3. DataFrame Unboxing
  puts "\nTesting DataFrame unboxing..."
  df = R.data__frame(a: R.c(1, 2), b: R.c(10.5, 20.5))
  begin
    df_native = df >> nil
    puts "DataFrame native keys: #{df_native.keys.inspect}"
    if df_native["a"] == [1, 2] && df_native["b"] == [10.5, 20.5]
      puts "SUCCESS: DataFrame unboxing works."
    else
      puts "FAILURE: DataFrame unboxing content mismatch: #{df_native.inspect}"
    end
  rescue => e
    puts "FAILURE: DataFrame unboxing raised error: #{e.message}"
  end

ensure
  R.bridge.close if R.respond_to?(:bridge)
end
