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

# load package and data
R.options(scipen: 999)  # turn-off scientific notation like 1e+48
R.theme_set(R.theme_bw)  # pre-set the bw theme.

midwest = ~:midwest
# midwest <- read.csv("http://goo.gl/G1K41K")  # bkup data source

R.awt

# Scatterplot
gg = midwest.ggplot(E.aes(x: :area, y: :poptotal)) + 
     R.geom_point(E.aes(col: :state, size: :popdensity)) + 
     R.geom_smooth(method: "loess", se: false) + 
     R.xlim(R.c(0, 0.1)) + 
     R.ylim(R.c(0, 500000)) + 
     R.labs(subtitle: "Area Vs Population", 
            y: "Population", 
            x: "Area", 
            title: "Scatterplot", 
            caption: "Source: midwest")

puts gg

sleep(2)
# a = gets.chomp
