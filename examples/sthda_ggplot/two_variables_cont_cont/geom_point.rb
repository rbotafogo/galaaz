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

# @bug: Next statement is not converting cyl to factor. Should investigate
# (~:mtcars).cyl = R.as__factor((~:mtcars).cyl)
# puts ~:mtcars
# b = R.ggplot(:mtcars, E.aes(x: :wt, y: :mpg))
   
R.awt

# Basic plot
print b + R.geom_point

sleep(2)
R.grid__newpage

# change the color and the point 
# by the levels of cyl variable
print b + R.geom_point(E.aes(color: :cyl, shape: :cyl)) 

sleep(2)
R.grid__newpage

# Change color manually
print b + R.geom_point(E.aes(color: :cyl, shape: :cyl)) +
      R.scale_color_manual(values: R.c("#999999", "#E69F00", "#56B4E9")) +
      R.theme_minimal

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window and creates a new one
R.dev__off
