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

tooth_growth = ~:ToothGrowth
tooth_growth.dose = tooth_growth.dose.as__factor
e = tooth_growth.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Default plot
print e + R.geom_jitter(position: R.position_jitter(0.2))

sleep(2)
R.grid__newpage

# Strip charts with mean points (+/- SD)
print e + R.geom_jitter(position: R.position_jitter(0.2)) + 
      R.stat_summary(fun__data: "mean_sdl",  fun__args: R.list(mult: 1), 
                     geom: "pointrange", color: "red")

sleep(2)
R.grid__newpage

# Combine with box plot
print e + R.geom_jitter(position: R.position_jitter(0.2)) + 
      R.geom_dotplot(binaxis: "y", stackdir: "center") 

sleep(2)
R.grid__newpage

# Add violin plot
print e + R.geom_violin(trim: false) +
      R.geom_jitter(position: R.position_jitter(0.2))
  

sleep(2)
R.grid__newpage

# Change color and shape by group (dose) 
print e + R.geom_jitter(E.aes(color: :dose, shape: :dose),
                        position: R.position_jitter(0.2))

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
