# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

economics = ~:economics
d = economics.ggplot(E.aes(x: :date, y: :unemploy))

R.awt

# Area plot
print d + R.geom_area

sleep(2)
R.grid__newpage

# Line plot: connecting observations, ordered by x
print d + R.geom_line

sleep(2)
R.grid__newpage

# Connecting observations by stairs
# a subset of economics data set is used
R.set__seed(1234)

# Remember that nrow is an R::Vector.  To use it in a Ruby range we
# need to 'pop' its value as Numeric
ss = economics[R.sample((1..economics.nrow.pop), 20), :all]

print ss.ggplot(E.aes(x: :date, y: :unemploy)) + 
      R.geom_step


sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
