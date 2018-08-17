# coding: utf-8
require '../config'
require 'cantata'

# This dataset comes from Baseball-Reference.com.
baseball = R.read__csv("baseball.csv")
# Lets look at the data available for Momeyball.
moneyball = baseball.subset(baseball.Year < 2002)
# Let's see if we can predict the number of wins, by looking at
# runs allowed (RA) and runs scored (RS).  RD is the runs difference.
# We are making a linear model for predicting wins (W) based on RD

moneyball.RD = moneyball.RS - moneyball.RA
wins_reg = R.lm(:W =~ :RD, data: moneyball)
wins_reg.summary.pp

