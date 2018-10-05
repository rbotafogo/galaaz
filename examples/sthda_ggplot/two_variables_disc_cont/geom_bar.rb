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

df = R.data__frame(dose: R.c("D0.5", "D1", "D2"),
                   len: R.c(4.2, 10, 29.5))

puts df.head

df2 = R.data__frame(supp: R.rep(R.c("VC", "OJ"), each: 3),
                   dose: R.rep(R.c("D0.5", "D1", "D2"), 2),
                   len: R.c(6.8, 15, 33, 4.2, 10, 29.5))
puts df2.head

f = df.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Basic bar plot
print f + R.geom_bar(stat: "identity")

sleep(2)
R.grid__newpage

# Change fill color and add labels
print f + R.geom_bar(stat: "identity", fill: "steelblue") +
      R.geom_text(E.aes(label: :len), vjust: -0.3, size: 3.5) +
      R.theme_minimal

sleep(2)
R.grid__newpage

# Change bar plot line colors by groups
print f + R.geom_bar(E.aes(color: :dose),
             stat: "identity", fill: "white")

sleep(2)
R.grid__newpage

# Change bar plot fill colors by groups
print f + R.geom_bar(E.aes(fill: :dose), stat: "identity")

sleep(2)
R.grid__newpage

g = df2.ggplot(E.aes(x: :dose, y: :len, fill: :supp)) 

# Stacked bar plot
print g + R.geom_bar(stat: "identity")

sleep(2)
R.grid__newpage

# Use position=position_dodge()
print g + R.geom_bar(stat: "identity", position: R.position_dodge)

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
