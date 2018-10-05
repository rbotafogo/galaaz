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

# Package Hmisc does not yet install on graalvm because of
# problems with package data.table
# Polyglot.eval("R", "library('Hmisc')")

tooth_growth = ~:ToothGrowth
tooth_growth.dose = tooth_growth.dose.as__factor
puts tooth_growth

e = tooth_growth.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Default plot
print e + R.geom_violin(trim: false)

sleep(2)
R.grid__newpage

# violin plot with mean points (+/- SD)
# R.stat_summary requires Hmisc
print e + R.geom_violin(trim: false) + 
      R.stat_summary(fun__data: "mean_sdl",  fun__args: E.list(mult: 1), 
                     geom: "pointrange", color: "red")

# sleep(2)
# R.grid__newpage

# Combine with box plot
print e + R.geom_violin(trim: false) + 
      R.geom_boxplot(width: 0.2)

sleep(2)
R.grid__newpage

# Color by group (dose) 
print e + R.geom_violin(E.aes(color: :dose), trim: false)

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
