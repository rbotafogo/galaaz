# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

# Scatter plot 
faithful = R.faithful
sp = faithful.ggplot(E.aes(x: :eruptions, y: :waiting)) 

R.awt

# example from ggplot contour using the z dimension
faithfuld = R.faithfuld
print faithfuld.ggplot(E.aes(:waiting, :eruptions, z: :density)) +
      R.geom_contour('')

sleep(2)
R.grid__newpage

# Default plot
print sp + R.geom_density_2d('')

sleep(2)
R.grid__newpage

# Add points
print sp + R.geom_point('') + R.geom_density_2d('')

sleep(2)
R.grid__newpage

# Use stat_density_2d with geom = "polygon"
print sp + R.geom_point('') + 
      R.stat_density_2d(E.aes_string(fill: '..level..'), geom: "polygon")

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off('')
