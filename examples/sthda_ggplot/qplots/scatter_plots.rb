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

require 'cantata'
require 'ggplot'

# Load the data
mtcars = ~:mtcars
df = mtcars[:all, R.c("mpg", "cyl", "wt")]

# Convert cyl to a factor variable
df.cyl = R.as__factor(df.cyl)
puts df.head

R.awt

# Basic scatter plot
print R.qplot(x: :mpg, y: :wt, data: df, geom: "point")

# wait 2 seconds for the next plog
sleep(2)
# clear the page
R.grid__newpage

# Scatter plot with smoothed line
# Calling qplot on a dataframe does not require the data: parameter
# nor print
df.qplot(:mpg, :wt, geom: R.c("point", "smooth"))

# wait 2 seconds for the next plog
sleep(2)
# clear the page
R.grid__newpage

# The following code will change the color and the shape of points by groups.
# The column cyl will be used as grouping variable. In other words, the color
# and the shape of points will be changed by the levels of cyl.
df.qplot(:mpg, :wt, colour: :cyl, shape: :cyl)


# wait 2 seconds for the next plog
sleep(2)
# clear the page
R.grid__newpage

# removes the window and creates a new one
R.dev__off
