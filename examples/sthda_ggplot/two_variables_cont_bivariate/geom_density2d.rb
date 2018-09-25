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

faithful = ~:faithful
sp = faithful.ggplot(E.aes(x: :eruptions, y: :waiting)) 

R.awt

# example from ggplot contour using the z dimension
faithfuld = ~:faithfuld
print faithfuld.ggplot(E.aes(:waiting, :eruptions, z: :density)) +
      R.geom_contour

sleep(2)
R.grid__newpage

# Default plot
print sp + R.geom_density_2d

sleep(2)
R.grid__newpage

# Add points
print sp + R.geom_point + R.geom_density_2d

sleep(2)
R.grid__newpage

# Use stat_density_2d with geom = "polygon"
print sp + R.geom_point + 
      R.stat_density_2d(E.aes_string(fill: '..level..'), geom: "polygon")

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
