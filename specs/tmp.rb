# coding: utf-8
require '../config'
require 'cantata'

R.library('MASS')
R.library('ISLR')

lst = R.list("Hello", "world", R.c(1, 2, 3), true, 2.45, ~:c)
puts lst


lm_fit5 = R.lm(R.formula("medv ~ poly(lstat, 5)"), data: :Boston)
#puts lm_fit5.summary



=begin
sym = +:sym
# construct a formula without the lhs: ~sym1 + sym2
puts +:sym1 + +:sym2
f1 = +:sym1 + :sym2
puts +:sym1 + +:sym2 - +:sym3
puts +:sym1 * +:sym2
=end

#puts :sym3 ** 2
# p (:sym1 + :sym2 * :sym3 ** 2).expression
#puts E.log(:y + 1).to_s

# puts :sym1 ** 2
# puts +:sym1 + (:sym1 ** 2).i

# puts +:y =~ +:sym1 + +:sym2 * +:sym3 + (:sym1 ** 2).i
# puts +:y =~ :all


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

=begin
# Set seed
R.set__seed(123)

# Data
x = R.rnorm(5)
x2 = R.rnorm(5)
y = R.rnorm(5)

# Model frame
puts R.model__frame(+:y =~ +:x * +:x2, data: R.data__frame(x: x, y: y, x2: x2))

puts R.model__frame(+:y =~ +:x + +:x2 + (+:x ^ +:x2),
                    data: R.data__frame(x: x, y: y, x2: x2))

puts R.model__frame(+:y =~ +:x + (:x ** 2).i,
                    data: R.data__frame(x: R.rnorm(5), y: R.rnorm(5)))
=end
