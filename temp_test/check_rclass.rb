
require 'galaaz'
R.library("stats")
x = R.list(a: (1..10))
q = ~:quantile
quant = R.sapply(x, q)
rc = quant.rclass
puts "quant.rclass type: #{rc.class}"
puts "quant.rclass interop: #{rc.r_interop}"
puts "quant.rclass to_s: #{rc.to_s}"
unboxed = rc >> nil
puts "Unboxed: #{unboxed.inspect}"
puts "Compare to 'matrix': #{rc == 'matrix'}"
puts "R-side check: #{R.bridge.eval_r("isTRUE(all.equal(class(#{quant.r_interop}), 'matrix'))")}"
