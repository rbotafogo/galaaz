# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2013 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
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

require '../config'
require 'cantata'

# evaluate an integer in R and return the result of this evaluation
# this is just an integer
var = R.eval("4")
max = R.eval("max")
min = R.eval("min")

puts ("Double evaluated in R: #{var}")
p var.is_a? Float

# Create a list in R, that is anonymous in R but available to Ruby.
# We are now using method_missing to resolve the 'c' method.
val = R.c(1, 2, 3, 4)
p R.typeof(val)
p R.max(val)

p "find max"
p Truffle::Interop.execute(max, val)
p max.call(val)
p R.max(val)
p "and find min"
p Truffle::Interop.execute(min, val)

p "R interop: #{val}"
p "R interop is foreign? #{Truffle::Interop.foreign?(val)}"

p "Ruby var is foreign? #{Truffle::Interop.foreign?(var)}"

p "Meta object from R interop: #{Truffle::Interop.meta_object(val)}"
p "It's superclass: #{Truffle::Interop.meta_object(val).superclass}"

p Truffle::Interop.meta_object(var)
p Truffle::Interop.meta_object(1)
p Truffle::Interop.meta_object("c")

class Teste

end

a = Teste.new
p Truffle::Interop.meta_object(a)

p Truffle::Interop.to_string(var)
p Truffle::Interop.to_string(val)
p Truffle::Interop.to_string(a)

=begin
p R.typeof(val)


# val is a foreigner object to Ruby...
p val

# ... yet, it can be called as Ruby object;
# Note that in Ruby, we have indexing starting at 0
p val[1]

# showing that evaluation works for method arguments
val = R.list(1, 2, R.c('a', 'b', 'c'))
# typeof val is "list"
p R.typeof(val)
# prints 'c'
p val[2][2]

# Lets try to replicate the rpy2 example.  We need to improve our method_missing
# to allow passing named parameters to an R function.
range = R.eval("1:10")
p range


m = R.matrix(1..10, nrow: 2,
             dimnames: R.list(R.c("1", "2"),
                              R.c("a", "b", "c", "d", "e")))
=end
