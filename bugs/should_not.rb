require 'galaaz'
R.install_and_loads('dplyr', 'readr')

dir = File.dirname(File.expand_path(__FILE__))

#=begin
# ler arquivo com dados financeiros.  Function read_csv2 is not 
# working on version 19.1.1
financas = R.read_csv2("#{dir}/finance.csv",
                       locale: R.locale(date_names: "br", decimal_mark: ",", 
                                        grouping_mark: ".", encoding: "UTF-8"))
#=end

# ler arquivo com dados financeiros
br_loc = R.locale(date_names: "br", decimal_mark: ",", grouping_mark: ".",
                  encoding: "UTF-8")

# financas = R.read__csv2("#{dir}/finance.csv", header: true)
# financas = financas.as_tibble

=begin
financas = R.type_convert(financas,
                          col_types: E.cols(
                            'Valor_Cota': R.col_double
                          )
                         )
=end
# val = R.parse_double("2583,60", locale: br_loc)
# puts val

financas =
  financas.
    mutate('VN': R.parse_double('Valor_Nominal', locale: br_loc))

=begin
financas =
  financas.
    mutate('Valor BRR': E.if_else((:Data.eq "04/12/2018"), 1.0, 3.86) *
                        'Valor.Nominal'
          )
=end

puts financas
