# coding: utf-8

if (!$CONFIG)
  require '../../config'
  require 'cantata'
end

R.library('ggplot2')
R.library('grid')
R.library('MASS')
R.library('ISLR')

# Simple linear regression from ISLR book.  Chapter 3 Lab

# load boston data frame on variable boston
boston = R.Boston

puts boston.names

boston_lm = R.lm(:medv =~ :lstat, data: boston)
# puts boston_lm.str
# puts boston_lm.summary
puts boston_lm.names
puts boston_lm.coef
puts boston_lm.confint
conf = R.predict(boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))), interval: "confidence")
puts conf
pred = R.predict(boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))), interval: "prediction")
puts pred

R.awt

puts R.qplot(boston.lstat, boston.medv, col: "red") +
     R.geom_abline(intercept: boston_lm.coef[1],
                   slope: boston_lm.coef[2],
                   color: "blue",
                   linetype: "dashed",
                   size: 1.5)

# uncomment if needed to pause while analysing graph. reads input from user 
# a = gets.chomp

# sleep two seconds so that the graph shows up
sleep(2)
R.grid__newpage('')

puts R.qplot(R.predict(boston_lm), R.residuals(boston_lm))

sleep(2)
R.grid__newpage('')

puts R.qplot(R.predict(boston_lm), R.rstudent(boston_lm))

sleep(2)
R.grid__newpage('')

vals = R.hatvalues(boston_lm)
# method size returns a Numeric... size is equivalent to 'length << 0'
puts R.qplot((1..vals.size), vals)

sleep(2)
R.grid__newpage('')
