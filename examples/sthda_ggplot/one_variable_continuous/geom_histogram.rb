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

R.set__seed(1234)

wdata = R.data__frame(
  sex: R.c("F", "M").rep(each: 200).factor,
  weight: R.c(R.rnorm(200, 55), R.rnorm(200,58)))

puts wdata.head

# We start by creating a plot, named 'a', that we’ll finish next by adding layers
a = wdata.ggplot(E.aes(x: :weight))

# Aggregate the data by sex
mu = R.aggregate(wdata.weight, by: R.list(wdata.sex), FUN: :mean)
mu.names = R.c("sex", "grp_mean")
puts mu

R.awt

# Basic plot
print a + R.geom_histogram

sleep(2)
R.grid__newpage

# change line colors by sex
print a + R.geom_histogram(E.aes(color: :sex), fill: "white",
                           position: "dodge")

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window and creates a new one
R.dev__off
