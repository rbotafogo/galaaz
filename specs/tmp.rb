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


R::Support.eval(<<-R)
  ene = function(x) {
    enexpr(x)
  }
R

R.len = 10
R.sd = 20
vec = R.c(1, 2, 3, 4)


e1 = R.expr(:len)
puts e1
puts e1.ast
puts e1.eval

e2 = :len + vec
puts e2
puts e2.ast
puts e2.eval

e3 = e2 - :sd
puts e3
puts e3.ast
puts e3.eval

=begin
e4 = oper_add("`+`", e1, vec)
puts e4
puts e4.ast
puts e4.eval

e2 = R.add(e1, vec)
puts e2
puts e2.ast
puts e2.eval

e3 = R.minus(e2, :sd)
puts e3
puts e3.ast
puts e3.eval
=end


#=begin
R.awt

df = ~:ToothGrowth
df.dose = df.dose.as__factor
puts df.head

df2 = R.data__frame(
  R.aggregate(df.len, by: R.list(df.dose), FUN: :mean),
  R.aggregate(df.len, by: R.list(df.dose), FUN: :sd)[2]
)

df2.names = R.c("dose", "len", "sd")
puts df2.head

#f1 = R.minus(:len, :sd)
#f2 = R.add(:len, :sd)

exp = (E.aes(x: :dose, y: :len, 
             ymin: :len - :sd,
             ymax: :len + :sd))

puts exp

f = df2.ggplot(E.aes(x: :dose, y: :len, 
                     ymin: :len - :sd,
                     ymax: :len + :sd))

puts f + R.geom_crossbar
sleep(2)
#=end

=begin
myenv = R.env
myenv.e1 = R.expr(:len)
myenv.e2 = R.expr(:sd)
myenv.e3 = R.expr(R.c(1, 2, 3, 4))

puts myenv.e1
puts myenv.e1.ast

puts myenv.e2
puts myenv.e2.ast

puts myenv.e3
puts myenv.e3.ast

e4 = R.expr(:e1 + :e2 + :e3)
puts e4
puts e4.ast
puts e4.eval(myenv.new_data_mask)

=end
#f = df2.ggplot(E.aes(x: :dose, y: :len, 
#                     ymin: :len - :sd,
#                     ymax: :len + :sd))



=begin
exp = +:x
puts exp
puts exp.ast

exp = exp + 5
puts exp
puts exp.ast

exp2 = :x + :y + 5
puts exp2
puts exp2.ast
puts exp2.eval

exp = :x + vec
puts exp
puts exp.ast
=end

=begin
R.len = R.c(1, 2, 3)


f = R.expr(E.c(2, 3))
puts f
puts R.ast(f)
puts f.eval

f = R.expr(E.c(:len, R.rownames(:mtcars)))
puts f
puts f.ast
puts f.eval

f = E.c(:len, R.rownames(:mtcars))
puts f
puts f.ast
puts f.eval


x = y = R.seq(-~:pi, ~:pi, length: 10)
df = R.data__frame(x: x, y: y)
#puts df

exp18 = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
puts exp18
puts R.ast(exp18)
puts exp18.eval(df)

#R.x = 10
#R.y = 15

exp0 = :x + :y
puts exp0
puts exp0.ast
puts exp0.eval(df)

exp = R::Language.build("`+`", :x, :y)
puts exp
puts exp.ast
puts exp.eval(df)

#exp = R.exprs("`+`", :x, :y).as__call
#puts exp
#puts exp.ast
#puts exp.eval

# exp2 = R.exprs("+", exp, 5).as__call
exp2 = R::Language.build("`+`", exp, 5)
puts exp2
puts exp2.ast
puts exp2.eval(df)
=end

=begin
exp15 = R.exprs("outer", :x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
puts exp15
puts R.ast(exp15)

func = R.as__call(exp15)
puts func
puts R.ast(func)
=end

=begin
args = R.exprs(:len, R.rownames(:mtcars))
puts args
puts R.ast(args)
puts R.do__call("c", args)
#puts R.exec("c", R.exec("c", R::Support.eval("splice").call(args.r_interop)))


#f = R.exec("c", arg)
#puts f
#puts R.ast(f)
#puts f.eval
=end

=begin
R.len = R.c(1, 2, 3)
exp0 = +:len
puts exp0
puts R.ast(exp0)
puts R.eval(exp0)


exp0_1 = R.quo(:len)
puts exp0_1
puts R.ast(exp0_1)
puts R.eval(exp0_1)


exp0_2 = R.expr(:len)
puts exp0_2
puts R.ast(exp0_2)
puts R.eval(exp0_2)

num_exp = R.expr(5)
puts num_exp
puts R.ast(num_exp)
puts num_exp.eval

str_exp = R.expr("hello")
puts str_exp
puts R.ast(str_exp)
puts str_exp.eval

range_exp = R.expr(1..5)
puts range_exp
puts R.ast(range_exp)
puts range_exp.eval

expsqr = R.quo(:a)
puts expsqr
puts R.ast(expsqr)

exps = R.exprs("mean", x: R.quo(:x), na__rm: true)
puts exps
puts R.ast(exps)

exp8_0 = R.exprs(:len, R.rownames(:mtcars))
puts exp8_0
puts R.ast(exp8_0)

exp8 = E.c(:len, R.rownames(:mtcars))
puts exp8
puts R.ast(exp8)
# puts exp8.eval

# exp13 = E.call2("mean", x: R.quo(:x), na__rm: true)
# puts exp13
# puts R.ast(exp13)

# Not working... making a range a not a neg range
# neg_range = R.expr(-(1...5))
# puts neg_range
# puts R.ast(neg_range)
# puts neg_range.eval
=end

=begin
R.len = R.c(1, 2, 3)
R.sd = R.c(10, 20, 30)
R.cmp = R.c(8, 22, 25)

exp0 = +:len
puts exp0
puts exp0.eval

num_exp = R::RubyExpression.build_uni_exp(5)
puts num_exp
puts num_exp.eval

str_exp = R::RubyExpression.build_uni_exp("hello")
puts str_exp
puts str_exp.eval

na_exp = R::RubyExpression.build_uni_exp(R::NA)
puts na_exp
puts na_exp.eval

range_exp = R::RubyExpression.build_uni_exp(1..5)
puts range_exp
puts range_exp.eval

neg_range = R::RubyExpression.build_uni_exp(-(1...5))
puts neg_range
puts neg_range.eval

puts "======"
exp1 = :len + :sd         # (len + sd)
puts exp1
puts R.ast(exp1)
puts exp1.class
p exp1
puts exp1.get_expr
puts "======"

puts exp1_1 = +:len + :sd
puts exp1_1
puts R.ast(exp1_1)
puts "======"

# Error: RuntimeError - object 'len' not found
puts R.eval(exp1)

lst = R.list(len: 1, sd: 2)
puts R.eval(exp1, lst)

exp2 = :len + :sd + 5
puts R.eval(exp2)

exp3 = :len + :sd ** 2
puts R.eval(exp3, lst)
puts exp3.eval(lst)
puts exp3.eval

exp4 = :sd >= :cmp
puts exp4.eval

exp5 = E.f
puts exp5

exp6 = E.sum(:len, :sd)
puts exp6
puts exp6.eval

exp7 = E.c(:len, ~:sd)
puts exp7
puts R.ast(exp7)
puts exp7.eval

exp8 = E.c(:len, R.rownames(:mtcars))
puts exp8
puts R.ast(exp8)
puts exp8.eval

exp9 = E.c(:len, label: R.rownames(:mtcars))
puts exp9
puts R.ast(exp9)

exp10 = E.c(:len, label: "hello there")
puts exp10
puts R.ast(exp10)

exp11 = E.c(:len, label: ~:mtcars)
puts exp11
puts R.ast(exp11)

exp12 = E.f(E.g(1, 2), E.h(3, 4, E.i))
puts exp12
puts R.ast(exp12)

# This does not work... using 'R.' goes through do.call and the value of 'x'
# is not defined... will need to rethink the way we use do.call to make it
# completely compatible with tidy evaluation
exp13 = E.call2("mean", x: :x, na__rm: true)
puts exp13
puts R.ast(exp13)

exp14 = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
puts exp14
puts R.ast(exp14)


# coerce operation
# exp5 = 5 + :sd
# puts exp5
# puts exp5.eval

=end

=begin
x = y = R.seq(-~:pi, ~:pi, length: 10)
df = R.data__frame(x: x, y: y)

a_env = R.new__env
a_env.obj = df

expr = R.with_env(:bang_bang, a_env)
puts R.get_expr(expr)

# puts (R.eval(R.with_env(:bang_bang, a_env)))
=end

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

lm_fit5 = R.lm(:medv ^ E.poly(:lstat, 5), data: :Boston)
puts lm_fit5.summary

# puts R.as__formula("~ f(x, y)")
exp = E.f(:x + :z, :y, (1..3), (3...1), -(9...4)) + :x + :y * 5 + :all - (1..5)
puts R.substitute(exp)

puts E.aes(x: :wt, y: :mpg)
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
exp = R::RubyExpression.build_uni_exp(:a)
puts exp

# creates an expression from another expression
exp2 = R::RubyExpression.build_uni_exp(exp)
puts exp2

# raise exception
# exp3 = R::RubyExpression.build_uni_exp("3 + 5")
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
=end
=begin
r1 = mtcars[1, :all]
p r1
puts r1


puts mtcars[[1]]
puts mtcars[[1, 1]]

lst = R.list(a: R.c(1, 2, 3), b: R.c(10, 20, 30))
puts lst[[1]]
# puts lst[1, 1]
=end

=begin
mtcars.each_row do |row, row_name|
  case row_name << 0
  when "Mazda RX4"
    # puts row
    # p row
    # p row['mpg']
    # puts row['mpg']
    row['mpg'] == 21
    # puts R.rclass((row['mpg'] == 21))
    # expect(row['mpg'] == 21).to eq true
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


=begin
describe R::Vector do
  
  context "When creating vectors" do

    it "should do 'each_row'" do

      mtcars = ~:mtcars
      
      mtcars.each_row do |row, row_name|
        case row_name << 0
        when "Mazda RX4"
          puts row['mpg']
          expect(row['mpg'] == 21).to eq true
        end
      end
    end
=end  
=begin    
    it "should allow changing an element of a vector attribute" do
      # pending "Need to implement new function for this"
      # set names
      @vect = R.c(1, 2, 3, 4, 5, 6)
      @vect.names = R.c("a", "b", "c", "d", "e", "f")
      
      @vect.names[2] = "hello"
      puts @vect.names
      puts @vect.names[2]
      
      # expect(@vect.names[2]).to eq R.c("hello")
    end
=end
    
#end

# R.new_object = R.rownames(:mtcars)
# rhs = R.rhs(R.as__formula("~ f(!!new_object)"))
# puts R.to_expr(rhs)

#a_env = R.env
#a_env.new_object = R.rownames(:mtcars)

#=begin
# puts R.expr(rhs)

# res = Q.f(R.rownames(:mtcars))
# puts R.expr(res)
#=end

=begin
vec = R.c(1, 2, 3)
a_env = R.new__env
a_env.obj = vec

expr = R.with_env(:bang_bang, a_env)
puts expr

f(x: !!vec)
=end


#=begin

=begin
quosure = Polyglot.eval("R", "lsd()")
R::Support.print_foreign(quosure)

ret = Polyglot.eval("R", "eval").call(quosure)
R::Support.print_foreign(ret)

R.eval(quosure)
=end


=begin
df = ~:ToothGrowth
df.dose = df.dose.as__factor
puts df.head

df2 = R.data__frame(
  R.aggregate(df.len, by: R.list(df.dose), FUN: :mean),
  R.aggregate(df.len, by: R.list(df.dose), FUN: :sd)[2]
)

df2.names = R.c("dose", "len", "sd")
puts df2.head

exp = (E.aes(x: :dose, y: :len, 
             ymin: :len - :sd,
             ymax: :len + :sd))

puts exp

puts R.ggplot(df2, exp).as__list

#f = df2.ggplot(E.aes(x: :dose, y: :len, 
#                     ymin: :len - :sd,
#                     ymax: :len + :sd))

=end
