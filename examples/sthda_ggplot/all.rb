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

# packages that need to be installed:
# install.packages('ggplot2')
# install.packages('grid')
# install.packages('gridExtra')

# install.packages('quantreg')
# install.packages('hexbin')

# Package Hmisc does not yet install on graalvm because of
# problems with package data.table
# install.packages('Hmisc')

# Library 'quantreg' is needed in misc
R.library('quantreg')
R.library('hexbin')
# Hmisc is not working on rc6
# R.library('Hmisc')

require_relative 'qplots/scatter_plots'
require_relative 'qplots/box_violin_dot'
require_relative 'one_variable_continuous/histogram_density'
require_relative 'scatter_gg'
require_relative 'one_variable_continuous/density_gg'
require_relative 'one_variable_continuous/geom_area'
require_relative 'one_variable_continuous/geom_density'
require_relative 'one_variable_continuous/geom_dotplot'
require_relative 'one_variable_continuous/geom_freqpoly'
require_relative 'one_variable_continuous/geom_histogram'
require_relative 'one_variable_continuous/stat'
require_relative 'one_variable_discrete/bar'
require_relative 'two_variables_cont_cont/geom_point'
require_relative 'two_variables_cont_cont/geom_smooth'
require_relative 'two_variables_cont_cont/misc'
require_relative 'two_variables_cont_bivariate/geom_bin2d'
require_relative 'two_variables_cont_bivariate/geom_hex'
require_relative 'two_variables_cont_bivariate/geom_density2d'
require_relative 'two_variables_cont_function/geom_area'
require_relative 'two_variables_disc_cont/geom_boxplot'
require_relative 'two_variables_disc_cont/geom_violin'
require_relative 'two_variables_disc_cont/geom_dotplot'
require_relative 'two_variables_disc_cont/geom_jitter'
require_relative 'two_variables_disc_cont/geom_line'
require_relative 'two_variables_disc_cont/geom_bar'
require_relative 'two_variables_disc_disc/geom_jitter'
require_relative 'two_variables_error/geom_crossbar'
