list.of.packages <- c('rlang', 'purrr', 'formula.tools')

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library('rlang')
library('purrr')
library('formula.tools')