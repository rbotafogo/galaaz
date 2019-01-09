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

puts :a == 4

=begin

# those two are different!!!
# '==' is used to compare :a with 4 returning FALSE
# while :a.eq becomes the expression (a == 4)
puts R.substitute(:a == 4)
puts R.substitute(:a.eq 4)

puts R.substitute(:a & 4)
puts R.substitute(:a.and 4)
puts R.substitute(:a | 4)
puts R.substitute(:a.or 4)

puts R.substitute(:a % 4)
puts R.substitute(:a.mod 4)

puts R.substitute((((:a * 4).gt 5) + 8).le 3)

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

=begin
a_env = R.new__env
puts a_env               # <environment: xxxx>
puts a_env.typeof
puts a_env.rclass

puts a_env.parent__env   # <environment: yyyy>
puts a_env.ls            # character(0)

a_env.set(:a, 25)
a_env.set(:b, 30)

puts a_env.ls             # [1] "a" "b"
puts a_env.get("a")       # [1] 25
puts a_env.get("b")       # [1] 30
puts a_env.a              # [1] 25
puts a_env[["a"]]         # [1] 25
puts a_env.c              # calls method 'c' on a_env

# puts a_env["a"]         # RuntimeError: Not subsettable
a_env.c = 40              # set the 'c' key to 40 
puts a_env.c              # No more a call to method 'c': [1] 40
a_env.d = R.c(1, 2, 3, 4)
puts a_env.d

# puts a_env.d              # RuntimeError: Error: object 'd' not found
=end
