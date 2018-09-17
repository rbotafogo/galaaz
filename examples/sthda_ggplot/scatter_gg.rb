# coding: utf-8
if (!$CONFIG)
  require '../../config' 
  require 'cantata'
end

R.awt

mtcars = ~:mtcars

# Basic scatter plot
# Rementer that with ggplot, print is necessary to output
# the plot.
print mtcars.ggplot(E.aes(x: :wt, y: :mpg)) + 
      R.geom_point

sleep(2)
R.grid__newpage

# Change the point size, and shape
print mtcars.ggplot(E.aes(x: :wt, y: :mpg)) +
      R.geom_point(size: 2, shape: 23)

sleep(2)
R.grid__newpage

# The function aes_string() can be used as follow:
print mtcars.ggplot(R.aes_string(x: "wt", y: "mpg")) +
      R.geom_point(size: 2, shape: 10)

sleep(2)
R.grid__newpage

# a = gets.chomp


# removes the window and creates a new one
R.dev__off
