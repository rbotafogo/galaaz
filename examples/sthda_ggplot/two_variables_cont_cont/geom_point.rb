# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

mtcars = R.mtcars
mtcars.cyl = R.as__factor(mtcars.cyl)

b = mtcars.ggplot(E.aes(x: :wt, y: :mpg))
   
R.awt

# Basic plot
print b + R.geom_point('')

sleep(2)
R.grid__newpage

# change the color and the point 
# by the levels of cyl variable
print b + R.geom_point(E.aes(color: :cyl, shape: :cyl)) 

sleep(2)
R.grid__newpage

# Change color manually
print b + R.geom_point(E.aes(color: :cyl, shape: :cyl)) +
      R.scale_color_manual(values: R.c("#999999", "#E69F00", "#56B4E9")) +
      R.theme_minimal('')

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window and creates a new one
R.dev__off('')
