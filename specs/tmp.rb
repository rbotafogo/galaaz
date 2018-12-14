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
require 'ggplot'

df = ~:ToothGrowth
df.dose = df.dose.as__factor
# puts df.head

df2 = R.data__frame(
  R.aggregate(df.len, by: R.list(df.dose), FUN: :mean),
  R.aggregate(df.len, by: R.list(df.dose), FUN: :sd)[2]
)

df2.names = R.c("dose", "len", "sd")
# puts df2.head

# f = df.ggplot(E.aes(x: :dose, y: :len, color: :supp, ymin: 0, ymax: 100)) 

f = df2.ggplot(E.aes(x: :dose, y: :len, 
                     ymin: :len - :sd,
                     ymax: :len + :sd))

aes = E.aes(x: :dose, y: :len, 
            ymin: :len - :sd,
            ymax: :len + :sd)

f2 = df2.ggplot(aes)
                              
# R.awt

R::Support.eval(<<-R)
rp = function(x) {
  lst = as.list(x)
  print(length(lst))
  print(lst[[1]])
  print(lst[[2]])
  print(lst[[3]])
  print(lst[[4]])
}

R

R.rp(aes)


=begin
[1] 4
<quosure>
expr: ^dose
env:  0xdef000000000f6b
<quosure>
expr: ^len
env:  0xdef000000000f6b
<quosure>
expr: ^.Primitive("-")(len, sd)
env:  0xdef000000000f6b
<quosure>
expr: ^.Primitive("+")(len, sd)
env:  0xdef000000000f6b
=end

# Default plot
# puts f # + R.geom_crossbar

=begin
R::Support.eval(<<-R)

# check in RC10 if works: "calling ruby from r" 
arr_class = eval.polyglot("ruby", "Array")
# print(arr_class@class())
arr = arr_class@new()
print(arr)
arr@insert(0, 10)
#print(arr$to_s)

R
=end



=begin
sym = +:sym
# construct a formula without the lhs: ~sym1 + sym2
puts +:sym1 + +:sym2
f1 = +:sym1 + :sym2
puts +:sym1 + +:sym2 - +:sym3
puts +:sym1 * +:sym2
=end

#puts :sym3 ** 2
# p (:sym1 + :sym2 * :sym3 ** 2).expression
#puts E.log(:y + 1).to_s

# puts :sym1 ** 2
# puts +:sym1 + (:sym1 ** 2).i

# puts +:y =~ +:sym1 + +:sym2 * +:sym3 + (:sym1 ** 2).i
# puts +:y =~ :all


# p sym
# puts sym
# sym.typeof
=begin
f1 = +:sym1 + +:sym2
puts f1
puts f1.deparse

puts R.c(1, 2, 3).deparse
puts R.list(a: 1, b: 2, c: 3).deparse
=end

=begin
# Set seed
R.set__seed(123)

# Data
x = R.rnorm(5)
x2 = R.rnorm(5)
y = R.rnorm(5)

# Model frame
puts R.model__frame(+:y =~ +:x * +:x2, data: R.data__frame(x: x, y: y, x2: x2))

puts R.model__frame(+:y =~ +:x + +:x2 + (+:x ^ +:x2),
                    data: R.data__frame(x: x, y: y, x2: x2))

puts R.model__frame(+:y =~ +:x + (:x ** 2).i,
                    data: R.data__frame(x: R.rnorm(5), y: R.rnorm(5)))
=end
=begin
class User
  
  attr_reader :id
  attr_reader :name
  attr_reader :favoriteLanguage
  
  def initialize(id, name, favorite_language)
    @id = id
    @name = name
    @favorite_language = favorite_language
  end
  
end

class NameColumn

  attr_reader :users
  
  def initialize(users)
    @users = users
  end

  def get(index)
    users[index].name
  end

  def set(index, val)
  end

  def getSize
    users.size
  end

  def method_missing(symbol, *args)
    puts "NameColumn method_missing"
    puts symbol
    puts args
  end
  
end

class IdColumn

  attr_reader :users
  
  def initialize(users)
    @users = users
  end

  def get(index)
    users[index].id
  end

  def set(index, val)
  end

  def getSize
    users.size
  end
  
  def method_missing(symbol, *args)
    puts "IdColumn method_missing"
    puts symbol
    puts args
  end

end

class UsersTable
  attr_reader :id
  attr_reader :name
  attr_reader :language

  def initialize(users)
    @users = users
    @id = IdColumn.new(users)
    @name = NameColumn.new(users)
  end

  def getSize
    puts users.size
    users.size
  end

  def method_missing(symbol, *args)
    puts "UsersTable method_missing"
    puts symbol
    puts args
  end
  
end

rf = R::Support.eval(<<-R)
  function(table) { 
    print(table);
    table <- as.data.frame(table);
    cat('The whole data frame printed in R:\n');
    print(table);
    cat('---------\n\n');

    cat('Filter out users with ID>2:\n');
    print(table[table$id > 2,]);
    cat('---------\n\n');

    cat('How many users like Java: ');
    cat(nrow(table[table$language == 'Java',]), '\n');
  }
R

users = []
users << User.new(1, "Florian", "Python")
users << User.new(2, "Lukas", "R")
users << User.new(3, "Mila", "Java")
users << User.new(4, "Paley", "Coq")
users << User.new(5, "Stepan", "C#")
users << User.new(6, "Tomas", "Java")
users << User.new(7, "Zbynek", "Scala")

puts users[0].name
ut = UsersTable.new(users)
rut = R.list(ut)
rf.call(rut)
=end
