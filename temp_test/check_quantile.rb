
require 'galaaz'
R.library("stats")
x = R.c(1..10)
q = R.quantile(x)
puts "Quantile result names: #{R.bridge.eval_r("names(#{q.r_interop})")}"

q1 = q[1]
target = R.c('0%': 1.0)

puts "q[1] class: #{R.bridge.eval_r("class(#{q1.r_interop})")}"
puts "target class: #{R.bridge.eval_r("class(#{target.r_interop})")}"
puts "q[1] names: #{R.bridge.eval_r("names(#{q1.r_interop})")}"
puts "target names: #{R.bridge.eval_r("names(#{target.r_interop})")}"
puts "identical: #{R.bridge.eval_r("identical(#{q1.r_interop}, #{target.r_interop})")}"
puts "Ruby ==: #{q1 == target}"
