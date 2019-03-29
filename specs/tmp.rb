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


#=begin
mtcars = ~:mtcars
# puts mtcars

# Assignment with '[<-'
mtcars["new column"] = R.c((1..32))
puts mtcars



=begin
# should allow mtcars[['car name']] = mtcars.rownames
=end





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
