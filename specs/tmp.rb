# coding: utf-8
require '../config'
require 'cantata'

sym = +:sym

R.sym = 10
puts ~:sym

puts R.eval(sym)

# p sym
# puts sym
# sym.typeof
=begin
f1 = +:sym1 + +:sym2
puts f1
puts f1.deparse

puts R.c(1, 2, 3).deparse
puts R.list(a: 1, b: 2, c: 3).deparse
=end
