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

lm_fit = R.lm(+:medv =~ +:lstat + +:age, data: ~:Boston)
R.print(lm_fit.summary)

R::Support.eval(<<-R)
  lm.fit = lm(medv ~ lstat + age, data = Boston)
  print(summary(lm.fit))
R
