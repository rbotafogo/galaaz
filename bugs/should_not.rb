require 'galaaz'
R.library 'tidyverse'

dir = File.dirname(File.expand_path(__FILE__))

# ler arquivo com dados financeiros
@financas = R.read_csv2("#{dir}/finance.csv",
                        locale: R.locale(date_names: "br", decimal_mark: ",", 
                                         grouping_mark: "."))

@financas =
  @financas.
    mutate('Valor BRR': :'Valor Nominal' *
                        E.if_else((:Data.eq "04/12/2018"), 1, 3.86))

