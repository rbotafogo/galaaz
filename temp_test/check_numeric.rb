
require 'galaaz'
vec = R.c(3, 5.7, 10, 12)
val = (vec >> 0)
puts "Value: #{val.inspect}"
puts "Class: #{val.class}"
puts "is_a? Numeric: #{val.is_a? Numeric}"
puts "is_a? Integer: #{val.is_a? Integer}"
puts "is_a? Float: #{val.is_a? Float}"
