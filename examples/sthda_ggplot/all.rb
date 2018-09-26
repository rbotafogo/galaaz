# coding: utf-8

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
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

# install.packages('quantreg')
# install.packages('hexbin')
# Library 'quantreg' is needed in misc
R.install_and_loads('quantreg', 'hexbin')

# Package Hmisc does not yet install on graalvm because of
# problems with package data.table
# install.packages('Hmisc')
# R.install_and_loads('Hmisc')

def exec(name)
  puts "=" * (name.size + 12)
  puts "Executing '#{name}'"
  puts "=" * (name.size + 12)
  require_relative name
end

exec "qplots/scatter_plots"
exec 'qplots/box_violin_dot'
exec 'one_variable_continuous/histogram_density'
exec 'scatter_gg'
exec 'one_variable_continuous/density_gg'
exec 'one_variable_continuous/geom_area'
exec 'one_variable_continuous/geom_density'
exec 'one_variable_continuous/geom_dotplot'
exec 'one_variable_continuous/geom_freqpoly'
exec 'one_variable_continuous/geom_histogram'
exec 'one_variable_continuous/stat'
exec 'one_variable_discrete/bar'
exec 'two_variables_cont_cont/geom_point'
exec 'two_variables_cont_cont/geom_smooth'
exec 'two_variables_cont_cont/misc'
exec 'two_variables_cont_bivariate/geom_bin2d'
exec 'two_variables_cont_bivariate/geom_hex'
exec 'two_variables_cont_bivariate/geom_density2d'
exec 'two_variables_cont_function/geom_area'
exec 'two_variables_disc_cont/geom_boxplot'
exec 'two_variables_disc_cont/geom_violin'
exec 'two_variables_disc_cont/geom_dotplot'
exec 'two_variables_disc_cont/geom_jitter'
exec 'two_variables_disc_cont/geom_line'
exec 'two_variables_disc_cont/geom_bar'
exec 'two_variables_disc_disc/geom_jitter'
exec 'two_variables_error/geom_crossbar'
