# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

mtcars = ~:mtcars
mtcars.cyl = R.as__factor(mtcars.cyl)

b = mtcars.ggplot(E.aes(x: :wt, y: :mpg))
   
R.awt

# Regression line only
print b + R.geom_smooth(method: :lm)

sleep(2)
R.grid__newpage

# Point + regression line
# Remove the confidence interval 
print b + R.geom_point + 
      R.geom_smooth(method: :lm, se: false)

sleep(2)
R.grid__newpage

# loess method: local regression fitting
print b + R.geom_point + R.geom_smooth

sleep(2)
R.grid__newpage

# Change color and shape by groups (cyl)
print b + R.geom_point(E.aes(color: :cyl, shape: :cyl)) + 
      R.geom_smooth(E.aes(color: :cyl, shape: :cyl), 
                    method: :lm, se: false, fullrange: true)

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window and creates a new one
R.dev__off
