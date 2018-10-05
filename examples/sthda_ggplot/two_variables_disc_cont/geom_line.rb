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

df = R.data__frame(supp: R.rep(R.c("VC", "OJ"), each: 3),
                   dose: R.rep(R.c("D0.5", "D1", "D2"), 2),
                   len: R.c(6.8, 15, 33, 4.2, 10, 29.5))
puts df.head


R.awt

# Change line types by groups (supp)
print df.ggplot(E.aes(x: :dose, y: :len, group: :supp)) +
      R.geom_line(E.aes(linetype: :supp)) +
      R.geom_point

sleep(2)
R.grid__newpage

# Change line types, point shapes and colors
print df.ggplot(E.aes(x: :dose, y: :len, group: :supp)) +
      R.geom_line(E.aes(linetype: :supp, color: :supp)) +
      R.geom_point(E.aes(shape: :supp, color: :supp))

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window
R.dev__off
