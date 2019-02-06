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

R.install_and_loads('Hmisc')

df = ~:ToothGrowth
df.dose = df.dose.as__factor
puts df.head

df2 = R.data__frame(
  R.aggregate(df.len, by: R.list(df.dose), FUN: :mean),
  R.aggregate(df.len, by: R.list(df.dose), FUN: :sd)[2]
)

df2.names = R.c("dose", "len", "sd")
puts df2.head

f = df2.ggplot(E.aes(x: :dose, y: :len, 
                     ymin: :len - :sd,
                     ymax: :len + :sd))

df3 = R.data__frame(
  R.aggregate(df.len, by: R.list(df.dose, df.supp), FUN: :mean),
  R.aggregate(df.len, by: R.list(df.dose, df.supp), FUN: :sd)[3]
)

df3.names = R.c("dose", "supp", "len", "sd")
puts df3.head

R.awt

# Default plot
puts f + R.geom_crossbar

sleep(2)
R.grid__newpage

# color by groups
print f + R.geom_crossbar(E.aes(color: :dose))

sleep(2)
R.grid__newpage

# Change color manually
print f + R.geom_crossbar(E.aes(color: :dose)) + 
      R.scale_color_manual(values: R.c("#999999", "#E69F00", "#56B4E9")) +
      R.theme_minimal

sleep(2)
R.grid__newpage

# fill by groups and change color manually
print f + R.geom_crossbar(E.aes(fill: :dose)) + 
      R.scale_fill_manual(values: R.c("#999999", "#E69F00", "#56B4E9")) +
      R.theme_minimal

sleep(2)
R.grid__newpage

f = df3.ggplot(E.aes(x: :dose, y: :len, 
                     ymin: :len - :sd, ymax: :len + :sd))

# Default plot
print f + R.geom_crossbar(E.aes(color: :supp))

sleep(2)
R.grid__newpage

# Use position_dodge() to avoid overlap
print f + R.geom_crossbar(E.aes(color: :supp), 
                          position: R.position_dodge(1))

sleep(2)
R.grid__newpage

f = df.ggplot(E.aes(x: :dose, y: :len, color: :supp)) 

# Use geom_crossbar()
print f + R.stat_summary(fun__data: "mean_sdl", fun__args: R.list(mult: 1), 
                         geom: "crossbar", width: 0.6, 
                         position: R.position_dodge(0.8))

# a = gets.chomp

# removes the window
sleep(2)
R.dev__off
