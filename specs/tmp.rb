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

# naturgy soluções

require 'galaaz'
# require 'ggplot'

=begin
puts R.substitute(:a ^ :cyl + :dep)
=end

# df = ~:ToothGrowth
# :ToothGrowth.dose = :ToothGrowth.dose.as__factor
# puts :ToothGrowth.head

#e = :ToothGrowth["dose"]
#puts e.ast
#puts e.eval

puts :ToothGrowth.dose
puts :ToothGrowth.dose.as__factor


#puts R.as__factor(:ToothGrowth["dose"])


=begin
df2 = R.data__frame(
  R.aggregate(df.len, by: R.list(df.dose), FUN: :mean),
  R.aggregate(df.len, by: R.list(df.dose), FUN: :sd)[2]
)

df2.names = R.c("dose", "len", "sd")
puts df2.head


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

f = df2.ggplot(E.aes(x: :dose, y: :len, 
                     ymin: :len - :sd,
                     ymax: :len + :sd))

puts f + R.geom_crossbar
sleep(2)
=end


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

exp = :a + 1
p exp
puts exp

puts R.ast(exp)

R.b = 20
R.a = 10
puts R.eval(exp)
puts R.eval_tidy(exp)
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

=end
