# coding: utf-8

if (!$CONFIG)
  require '../../config'
  require 'cantata'
end

R.library('ggplot2')
R.library('grid')
R.library('MASS')
R.library('ISLR')

# Multiple linear regression from ISLR book.  Chapter 3 Lab, pg 113
lm_fit = R.lm(+:medv =~ +:lstat + +:age, data: :Boston)
puts lm_fit.summary



#   Non-linear Transformations of the Predictors
# Creating a more complex formula requires the use of R.formula
lm_fit5 = R.lm(R.formula("medv ~ poly(lstat, 5)"), data: :Boston)
puts lm_fit5.summary
