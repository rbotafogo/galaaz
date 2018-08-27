# coding: utf-8
require '../../config'
require 'cantata'

R.set__seed(1234)
wdata = R.data__frame(
  sex: R.c("F", "M").rep(each: 200).factor,
  weight: R.c(R.rnorm(200, 55), R.rnorm(200,58)))
puts wdata.head

# We start by creating a plot, named 'a', that we’ll finish next by adding layers
a = wdata.ggplot(E.aes(x: :weight))

# Aggregate the data by sex
mu = R.aggregate(wdata.weight, by: R.list(wdata.sex), FUN: :mean)
mu.names = R.c("sex", "grp_mean")
puts mu

R.awt

# Empirical Cumulative Density Function
print a + R.stat_ecdf('')

sleep(2)
R.grid__newpage

# quantile plot
print R.mtcars.ggplot(E.aes(sample: :mpg)) + R.stat_qq('')

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window and creates a new one
R.dev__off('')
