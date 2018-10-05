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

mtcars = ~:mtcars
mtcars.cyl = R.as__factor(mtcars.cyl)
puts mtcars

b = mtcars.ggplot(E.aes(x: :wt, y: :mpg))
   
R.awt

# Regression line only
print b + R.geom_smooth(method: :lm)

sleep(2)
R.grid__newpage

# Point + regression line
# Remove the confidence interval 
print b + R.geom_point + 
      R.geom_smooth(method: :lm, se: false)

sleep(2)
R.grid__newpage

# loess method: local regression fitting
print b + R.geom_point + R.geom_smooth

sleep(2)
R.grid__newpage

# Change color and shape by groups (cyl)
print b + R.geom_point(E.aes(color: :cyl, shape: :cyl)) + 
      R.geom_smooth(E.aes(color: :cyl, shape: :cyl), 
                    method: :lm, se: false, fullrange: true)

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window and creates a new one
R.dev__off
