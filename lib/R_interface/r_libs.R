list.of.packages <- c('rlang', 'purrr', 'formula.tools', 'lobstr', 'rticles')

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

if (!('data.table' %in% installed.packages()[, "Package"])) {
  install.fastr.packages('data.table')
}

library('formula.tools')
library('lobstr')
library('rlang')
library('purrr')

