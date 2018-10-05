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

economics = ~:economics

d = economics.ggplot(E.aes(x: :date, y: :unemploy))

R.awt

# Area plot
print d + R.geom_area

sleep(2)
R.grid__newpage

# Line plot: connecting observations, ordered by x
print d + R.geom_line

sleep(2)
R.grid__newpage

# Connecting observations by stairs
# a subset of economics data set is used
R.set__seed(1234)

# Remember that nrow is an R::Vector.  To use it in a Ruby range we
# need to 'pop' its value as Numeric
ss = economics[R.sample((1..economics.nrow.pop), 20), :all]

print ss.ggplot(E.aes(x: :date, y: :unemploy)) + 
      R.geom_step


sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
