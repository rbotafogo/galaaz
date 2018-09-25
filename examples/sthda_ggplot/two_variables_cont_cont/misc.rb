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

Polyglot.eval("R", "library('quantreg')")

R.awt

# geom_quantile(): Add quantile lines from a quantile regression
print R.ggplot(~:mpg, E.aes(:cty, :hwy)) +
      R.geom_point + R.geom_quantile +
      R.theme_minimal


sleep(2)
R.grid__newpage

print R.ggplot(~:mpg, E.aes(:cty, :hwy)) +
      R.geom_point + R.stat_quantile(quantiles: R.c(0.25, 0.5, 0.75))

sleep(2)
R.grid__newpage

# geom_rug(): Add marginal rug to scatter plots
# Add marginal rugs using faithful data

print (~:faithful).ggplot(E.aes(x: :eruptions, y: :waiting)) +
      R.geom_point + R.geom_rug

sleep(2)
R.grid__newpage

# geom_jitter(): Jitter points to reduce overplotting

plot = (~:mpg).ggplot(E.aes(:displ, :hwy))

# Default scatter plot
plot = plot + R.geom_point

# Use jitter to reduce overplotting
plot = plot + R.geom_jitter(
         position: R.position_jitter(width: 0.5, height: 0.5))
print plot

sleep(2)
R.grid__newpage

#
mtcars = ~:mtcars
mtcars.cyl = R.as__factor(mtcars.cyl)
b = mtcars.ggplot(E.aes(x: :wt, y: :mpg))

print b + R.geom_text(E.aes(label: R.rownames(mtcars)))

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
