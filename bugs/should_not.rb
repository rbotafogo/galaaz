# coding: utf-8
require 'galaaz'

=begin
@financas = 
  @financas.
    mutate("Data do Levantamento": E.parse_date(:Data, format: "%d/%m/%Y"),
           "Valor BRR": "Valor Nominal" * R.if_else(Moeda.x == "R$", 1, Valor),
           "Valor US$": "Valor Nominal" * R.if_else(Moeda.x == "R$", 1/Valor, 1)).
    mutate("Valor BRR": R.br_acc("Valor BRR"),
           "Valor US$": R.br_acc("Valor US$"))
=end

# exp = (:'Valor Nominal' * E.if_else((:'Moeda.x'.eq "R$"), 1, :'Valor'))
# exp = (:'Valor Nominal' * (E.if_else((:'Moeda.x'.eq "R$"), 1, 1.5)))
# puts exp

#=begin
R.library 'tidyverse'

# coding: utf-8
# ler arquivo com dados financeiros
@financas = R.read_csv2('finance.csv',
                        locale: R.locale(date_names: "br", decimal_mark: ",", 
                                         grouping_mark: "."))

@financas.str

@financas =
  @financas.
    mutate('Valor BRR': :'Valor Nominal' *
                        E.if_else((:Data.eq "04/12/2018"), 1, 3.86))

=begin
@financas =
  @financas.
    left_join(@contas).
    left_join(@taxas, by: "Data").
    # mutate('Data do Levantamento': E.parse_date(:Data, format: "%d/%m/%Y"))
    mutate('Data do Levantamento': :Data.parse_date(format: "%d/%m/%Y"),
           'Valor BRR': :'Valor Nominal' *
                        E.if_else((:'Moeda.x'.eq "R$"), 1, :Valor))

@financas =
  @financas.
    mutate('Valor BRR': :'Valor Nominal' *
                        E.if_else((:Moeda.eq "R$"), 1, :Valor))
=end

=begin
# ler arquivo de contas
@contas = R.read_csv2('Contas.csv')

# converter tipo de conta para 'fator'
@contas.Tipo = @contas.Tipo.as__factor

# número total de níveis disponíveis
@tipos_inv = @contas.Tipo.nlevels

# Completar tabela de finanças com informações
# das contas
@financas =
  @financas.
    left_join(@contas)

# ler tabela de taxas
@taxas = R.read_csv2('Taxas.csv')

# Completar tabela de finanças com informações
# das taxas
@financas = 
  @financas.
    left_join(@taxas, by: "Data")
#=end


#=begin
@financas =
  @financas.
    mutate('Valor BRR': exp)

puts @financas.as__data__frame.head
@financas.str

=end



