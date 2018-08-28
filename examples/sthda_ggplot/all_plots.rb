# coding: utf-8
require '../../config'
require 'cantata'

# packages that need to be installed:
# install.packages('quantreg')
# install.packages('hexbin')

# Package Hmisc does not yet install on graalvm because of
# problems with package data.table
# install.packages('Hmisc')

# Library 'quantreg' is needed in misc
Polyglot.eval("R", "library('quantreg')")
Polyglot.eval("R", "library('hexbin')")
# Polyglot.eval("R", "library('Hmisc')")


require_relative 'scatter_plots'
require_relative 'box_violin_dot'
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


