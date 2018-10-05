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

tooth_growth = ~:ToothGrowth
tooth_growth.dose = tooth_growth.dose.as__factor
puts tooth_growth

e = tooth_growth.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Default plot
print e + R.geom_dotplot(binaxis: "y", stackdir: "center")

sleep(2)
R.grid__newpage

# Dot plot with mean points (+/- SD)
# stat_summary requires library Hmisc that does not yet install in
# graalvm
# print e + R.geom_dotplot(binaxis: "y", stackdir: "center") + 
#      R.stat_summary(fun__data: "mean_sdl",  fun__args: E.list(mult: 1), 
#                     geom: "pointrange", color: "red")

sleep(2)
R.grid__newpage

# Combine with box plot
print e + R.geom_boxplot + 
      R.geom_dotplot(binaxis: "y", stackdir: "center") 
  
sleep(2)
R.grid__newpage

# Add violin plot
print e + R.geom_violin(trim: false) +
      R.geom_dotplot(binaxis: 'y', stackdir: 'center')

sleep(2)
R.grid__newpage

# Color and fill by group (dose) 
print e + R.geom_dotplot(E.aes(color: :dose, fill: :dose), 
                         binaxis: "y", stackdir: "center")

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
