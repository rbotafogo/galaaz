# coding: utf-8
##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
# and distribute this software and its documentation, without fee and without a signed 
# licensing agreement, is hereby granted, provided that the above copyright notice, this 
# paragraph and the following two paragraphs appear in all copies, modifications, and 
# distributions.
#
# IN NO EVENT SHALL RODRIGO BOTAFOGO BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF 
# THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RODRIGO BOTAFOGO HAS BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# RODRIGO BOTAFOGO SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE 
# SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS". 
# RODRIGO BOTAFOGO HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
# OR MODIFICATIONS.
##########################################################################################

require 'galaaz'
require 'ggplot'

R.install_and_loads('ISLR', 'MASS')

# Simple linear regression from ISLR book.  Chapter 3 Lab

# load boston data frame on variable boston
boston = ~:Boston

puts boston.names

boston_lm = R.lm(+:medv =~ +:lstat, data: :Boston)
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
R.grid__newpage

puts R.qplot(R.predict(boston_lm), R.residuals(boston_lm))

sleep(2)
R.grid__newpage

puts R.qplot(R.predict(boston_lm), R.rstudent(boston_lm))

sleep(2)
R.grid__newpage

vals = R.hatvalues(boston_lm)
# method size returns a Numeric... size is equivalent to 'length << 0'
puts R.qplot((1..vals.size), vals)

sleep(2)
R.grid__newpage
