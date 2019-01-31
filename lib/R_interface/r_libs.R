list.of.packages <- c('rlang', 'purrr', 'formula.tools', 'lobstr')

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library('formula.tools')
library('lobstr')
library('rlang')
library('purrr')
