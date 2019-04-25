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

require 'galaaz'
# require 'ggplot'

R.library('data.table')
R.install_and_loads('curl')

input = "https://raw.githubusercontent.com/Rdatatable/data.table/master/vignettes/flights14.csv"
@flights = R.fread(input)
puts @flights
puts @flights.dim


data_table = R.data__table(
  ID: R.c("b","b","b","a","a","c"),
  a: (1..6),
  b: (7..12),
  c: (13..18)
)

puts data_table
puts data_table.ID

# ubset rows in i

ans = @flights[(:origin.eq "JFK") & (:month.eq 6)]
puts ans.head

# Get the first two rows from flights.

ans = @flights[(1..2)]
puts ans

# Sort flights first by column origin in ascending order, and then by dest in descending order:

# ans = @flights[E.order(:origin, -(:dest))]
# puts ans.head

# Select column(s) in j

# select arr_delay column, but return it as a vector.

ans = @flights[:all, :arr_delay]
puts ans.head

# Select arr_delay column, but return as a data.table instead.

ans = @flights[:all, :arr_delay.list]
puts ans.head

ans = @flights[:all, E.list(:arr_delay, :dep_delay)]

## Renaming columns

#The rename function is used to rename columns

#```{ruby rename}
#puts @flights.rename(dep_time: 'deptime').head.as__data__frame
#```


# puts File.directory?(".")





#===========================================================
=begin
# Add NULL to an element of the list
# Not implemented yet.  Need to assing the
# list(NULL) element.
R::Support.eval(<<-R)
y <- list(a = 1, b = 2)
y["b"] <- list(NULL)
str(y)

print(list(NULL))
R
=end


=begin
Polyglot.eval("R", <<-R)
  fidx = function(idx) {
      print(typeof(idx))
      print(class(idx))
      print(idx)
      print(is_missing(idx))
  }

  ma = missing_arg()
  f = fidx
  params = list()
  params = `[[<-`(params, 1, ma)
  invoke(f, params)

  print("======")
  fidx(ma)

R
=end

=begin
ma = Polyglot.eval("R", "missing_arg()")

puts "======"

f = Polyglot.eval("R", "fidx")
params = Polyglot.eval("R", "list()")
params = Polyglot.eval("R", "`[[<-`").call(params, 1, ma)
Polyglot.eval("R", "invoke").call(f, params)

puts "======"

Polyglot.eval("R", "fidx").call(ma)
=end

# Polyglot.eval("R", "print").call(pl)
# ma2 = Polyglot.eval("R", "`[[`").call(pl, 1)
# Polyglot.eval("R", "fidx").call(ma2)

#R.fidx(ma)

# R.fidx(Polyglot.eval("R", "missing_arg()"))
# R.fidx(R.empty_symbol)
