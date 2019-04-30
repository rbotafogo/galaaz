# coding: utf-8

require 'galaaz'

local_dir = File.expand_path File.dirname(__FILE__)

# This dataset comes from Baseball-Reference.com.
baseball = R.read__csv("#{local_dir}/baseball.csv")

# Lets look at the data available for Momeyball.
moneyball = baseball.subset(baseball.Year < 2002)

# Let's see if we can predict the number of wins, by looking at
# runs allowed (RA) and runs scored (RS).  RD is the runs difference.
# We are making a linear model for predicting wins (W) based on RD
moneyball.RD = moneyball.RS - moneyball.RA
wins_reg = R.lm((:W.til :RD), data: moneyball)

def show(title, data)
  puts title
  puts "=" * title.size
  puts data
  puts "=" * title.size
  puts
end

puts "Fitting a linear model on the Baseball dataset as done in Moneyball:"
puts
show "Coefficients of the Linear Regression", wins_reg.coefficients
show "Fitted values summary:", wins_reg.fitted__values.summary
show "Residuals summary", wins_reg.residuals.summary


