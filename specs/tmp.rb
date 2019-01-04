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
#require 'ggplot'

R.library('lobstr')
R.library('rlang')

R::Support.eval(<<-R)
  ast = function(x) {
    ex = enexpr(x)
    lobstr::ast(!!ex)
  }
 
  bang_bang = function() {
    print("in bang_bang")
    x = enquo(obj)
    # enexpr(class(!!x))
    print(x)
    x
  }

  with_env <- function(f, e=parent.frame()) {
    stopifnot(is.function(f))
    environment(f) <- e
    f()
  }

  #x = y = seq(-pi, pi, length = 10)
  #df = data.frame(x = x, y = y)
  #print(df)
  
  #x1 = expr(class(!!df))
  #print(x1)

  #a_env = new.env()
  #a_env$obj = df
  #print(rhs(eval(with_env(bang_bang, a_env))))
  #print(eval_tidy(with_env(bang_bang, a_env)))

  # print(expr(f(label: !!rownames(mtcars))))
R


#=begin
x = y = R.seq(-~:pi, ~:pi, length: 10)
df = R.data__frame(x: x, y: y)

a_env = R.new__env
a_env.obj = df
# puts (R.eval_tidy(R.with_env(:bang_bang, a_env

=begin
proc = lambda { |x, y| R.cos(y) / (1 + x**2) }
f = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
puts R.ast(f)
puts f
f.environment = R.c(env: f.environment, proc: proc)
# f.environment = R.c(f.environment, df)
puts f.environment
puts R.eval(f, df, R.list2env(f.environment))

# R.filter(df, E.outer(:x, :y))

=end

# puts R.eval_tidy(R.rhs(f), df)

=begin

R.a = 10
exp = :a + 1
# puts R.eval_tidy(exp)
# puts R.eval_tidy(R.rhs(exp))

exp = :b + (:a + 1)
R.b = 20
# puts R.eval_tidy(exp)
puts exp
puts R.eval_tidy(R.rhs(exp))

x = y = R.seq(-~:pi, ~:pi, length: 10)
df = R.data__frame(x: x, y: y)
puts df

f = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
puts f
puts R.get_env(f)

puts "============="

exp = :a + 1
p exp
puts exp

puts R.ast(exp)

R.b = 20
R.a = 10
puts R.eval(exp)
puts R.eval_tidy(exp)

x = y = R.seq(-~:pi, ~:pi, length: 10)
df = R.data__frame(x: x, y: y)
puts df

proc = lambda { |x, y| R.cos(y) / (1 + x**2) }
f = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
puts R.ast(f)
puts f
f.environment = R.c(env: f.environment, proc: proc)
f.environment = R.c(f.environment, df)
puts f.environment
puts R.eval(f, f.environment)
=end

=begin
R.a = 10

exp = !!:a + 1
puts R.ast(exp)

exp = 1 + :a * :b ** 5 + "hello"
puts exp

exp = E.f(:x + :z, :y, (1..3), (3...1), -(9...4)) + :x + :y * 5 + :all
puts exp

exp = E.geom_areas(E.aes_string(y: "..density.."), stat: "bin")
puts exp

exp = E.aes(label: E.rownames(:mtcars))
puts exp

exp = E.aes(label: E.c(1, 2, 3, 4))
expr = R.expr(exp)
puts R.ast(expr)

#mtcars = ~:mtcars
#exp = E.aes(label: mtcars)
#puts R.ast(exp)

=end

=begin
R.install_and_loads('ISLR', 'MASS')

lm_fit5 = R.lm(:medv ^ Q.poly(:lstat, 5), data: :Boston)
puts lm_fit5.summary

# puts R.as__formula("~ f(x, y)")
exp = Q.f(:x + :z, :y, (1..3), (3...1), -(9...4)) + :x + :y * 5 + :all - (1..5)
puts R.substitute(exp)

puts Q.aes(x: :wt, y: :mpg)
=end

=begin
R.awt

mtcars = ~:mtcars

# puts mtcars

# Basic scatter plot
# Rementer that with ggplot, print is necessary to output
# the plot.
print mtcars.ggplot(E.aes(x: :wt, y: :mpg)) + 
      R.geom_point

sleep(2)
R.grid__newpage
=end

=begin

puts R.substitute(:a ^ :cyl + :dep)


puts R.eval(:a >= 4, sample_df)
puts R.eval((:a.eq 4), sample_df)

sample_df = R.data__frame(a: (1..5), b: (5..1), c: R.c(5, 3, 1, 4, 1))
puts sample_df

# Ruby way of evaluation code in the scope of an object
r = sample_df.instance_eval {a == 4}
puts r
=end

=begin
def subset(df, condition)
  r = R.eval(condition, df)
  df[r, :all]  
end

puts subset(sample_df, :a >= 4)

puts subset(sample_df, :a == 4)
=end


=begin
exp = :len + :sd         # (len + sd)
aes = E.aes(x: :dose, y: :len, 
            ymin: :len - :sd,
            ymax: :len + :sd)

# puts aes
# R::Support.print_str(aes)

lst = aes.as__list

puts "====="
l = lst[[3]]
puts l
puts l.rclass
puts "====="

# R.f1(lst, lst[[3]])

# puts 5 + :cyl
=end

=begin
boston_lm = R.lm(:medv ^ :lstat, data: :Boston)


R::Support.eval(<<-R)
foo <- function(x) {
  enquo(x)
}

# print(foo(a + b))
print(quo(a))
R

puts R.as_quosure(R.as__formula(". ~ len + sd"))
#puts R.as_quosure(:len + :sd)
#puts R.new_quosure(:len + :sd)
=end

=begin

# those are quosures
exp = :len + :sd         # (len + sd)
exp = :len + :sd + 5     # ((len + sd) + 5)
exp = :len + :sd * 5     # (len + (sd * 5))

# those are formulas: have a '^' operator
exp = :y ^ :len + :sd    # (y ~ (len + sd))

aes = E.aes(x: :dose, y: :len, 
            ymin: exp)

R::Support.print_str(aes)

=end


=begin
aes = E.aes(x: :dose, y: :len, 
            ymin: :len - :sd,
            ymax: :len + :sd)

puts aes
=end

#R::Support.print_struct(aes)

=begin
# creates an expression from a Symbol
exp = R::Expression.build(:a)
puts exp

# creates an expression from another expression
exp2 = R::Expression.build(exp)
puts exp2

# raise exception
# exp3 = R::Expression.build("3 + 5")
# puts exp3

puts :a + :b * :c
puts :a + :b * :c ** 5
exp5 = (:a + :b) * :c ** 5.3
rexp = R.parse(text: exp5.to_s)
puts rexp
puts rexp.rclass
lst = rexp.as__list
puts lst[[1]]

# puts :a + :b

lang = R::Language.build("`+`", R.as__symbol("cyl"), 5)
puts lang
p lang
p lang.rclass

=end



=begin
class ArrayEmul
  attr_reader :array

  def initialize
    @array = []
  end

  def method_missing(symbol, *args)
    @array.send(symbol, *args)
  end

  def to_s
    @array.to_s
  end

  def pp
    puts @array.to_s
  end

  def fetch(index)
    @array[index[0]]
  end
  
end

make_obj = Polyglot.eval("R", <<-R)
  function(ruby_obj) {
    x = list(ruby_obj);
    attr(x, "class") = "ruby_obj";
    x;
   }
R

rf = Polyglot.eval("R", <<-R)
  function(ruby_obj) {
    # print(ruby_obj);
    attr(ruby_obj, "class") = "ruby_obj"
    print(ruby_obj@to_s());
    print(class(ruby_obj));
    # df = data.frame(ruby_obj);
  }

  print.ruby_obj = function(x, index, ...) {
    print(index);
    x[[1]]@fetch(index);
  }

R

h = ArrayEmul.new
h << 1 << 2 << 3
puts h

r_obj = make_obj.call(h)
p Polyglot.eval("R", "print").call(r_obj, 0)[0]

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
