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

# Minimal breadcrumb logging to understand where the script gets stuck
# when running `rake islr:all` (chapters are executed as scripts).
def galaaz_islr_debug(msg)
  STDERR.puts "[DEBUG islr][ch3_boston] #{Time.now.strftime('%H:%M:%S')} #{msg}"
  STDERR.flush
end

# Simple linear regression from ISLR book.  Chapter 3 Lab
# We are using qplot for plotting.  It would be better to use
# ggplot2, but this is just to show simple ploting.

# load boston data frame on variable boston
bala = nil
bala2 = nil
galaaz_islr_debug('start; loading Boston')
boston = ~:Boston
galaaz_islr_debug('Boston loaded; printing names/lm')

puts boston.names

boston_lm = R.lm((:medv.til :lstat), data: :Boston)
# puts boston_lm.str
# puts boston_lm.summary
puts boston_lm.names
puts boston_lm.coef
puts boston_lm.confint
conf = R.predict(boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))), interval: "confidence")
puts conf

pred = R.predict(boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))), interval: "prediction")
puts pred

puts boston.lstat
puts boston.medv

galaaz_islr_debug('before R.awt')
R.awt
galaaz_islr_debug('after R.awt; before first plot')

puts R.qplot(:lstat, :medv, data: :Boston, col: "red") +
     R.geom_abline(intercept: boston_lm.coef[1],
                   slope: boston_lm.coef[2],
                   color: "blue",
                   linetype: "dashed",
                   size: 1.5)

# uncomment if needed to pause while analysing graph. reads input from user 
# a = gets.chomp

# sleep two seconds so that the graph shows up
galaaz_islr_debug('sleep(2) after first plot')
sleep(2)
galaaz_islr_debug('grid__newpage #1')
R.grid__newpage

galaaz_islr_debug('building my_data #2 and plotting #2')
R.my_data = R.data__frame(pred: R.predict(boston_lm), res: R.residuals(boston_lm))
puts R.qplot(:pred, :res, data: :my_data)

galaaz_islr_debug('sleep(2) after plot #2')
sleep(2)
galaaz_islr_debug('grid__newpage #2')
R.grid__newpage

galaaz_islr_debug('building my_data #3 and plotting #3')
R.my_data = R.data__frame(pred: R.predict(boston_lm), res: R.rstudent(boston_lm))
puts R.qplot(:pred, :res, data: :my_data)

galaaz_islr_debug('sleep(2) after plot #3')
sleep(2)
galaaz_islr_debug('grid__newpage #3')
R.grid__newpage

galaaz_islr_debug('hatvalues + plotting #4')
vals = R.hatvalues(boston_lm)
R.my_data = R.data__frame(size: (1..vals.size), values: vals)
# method size returns a Numeric... size is equivalent to 'length << 0'
puts R.qplot(:size, :values, data: :my_data)

galaaz_islr_debug('sleep(2) after plot #4')
sleep(2)
galaaz_islr_debug('grid__newpage #4')
R.grid__newpage

# Close the graphics device so later chapters don't keep an open AWT window.
R.dev__off
