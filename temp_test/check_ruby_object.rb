
require 'galaaz'

class RData
  def val; 5; end
end

obj = RData.new
handle = R::Support.register_ruby_object(obj)
puts "Registered handle: #{handle}"

# Try to store in R and get back
R.bridge.eval_r("my_obj <- '#{handle}'")
res = R.bridge.pull_value("my_obj")
puts "Pulled value: #{res.inspect}"
puts "Is RData? #{res.is_a? RData}"

# Try with R.c
vec = R.c(obj)
puts "Vec interop: #{vec.r_interop}"
puts "Vec content in R: #{R.bridge.eval_r(vec.r_interop)}"
el = vec[[1]]
puts "Element 1 type: #{el.class}"
puts "Element 1 unboxed: #{el.unboxed_get(0).inspect}"
