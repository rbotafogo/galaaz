# coding: utf-8

require 'galaaz'
require 'ggplot'

faithful = ~:faithful

# sp is the basic plot having in the x axis the eruption data and in y the waiting

# Note that function 'aes' is called with E.aes. This prevents the execution of the aes function and

# passes it “as-is” to function ggplot.  Note that :eruption and :waiting are column names for the

# faithful data frame and do not exist in the scope of the aes method.  Calling aes with R.aes will fail.

sp = faithful.ggplot(E.aes(x: :eruptions, y: :waiting)) 

# create the output device for plotting

R.awt

# Use stat_density_2d with geom = "polygon"

# Note that in order to call a method without any arguments we pass an empty argument list.

# in Ruby, parenthesis are unnecessary, however in R, writing the function name without

# parenthesis returns the actual function and not a call to it.

print sp + R.geom_point + 
      R.stat_density_2d(E.aes_string(fill: '..level..'),
                        geom: "polygon")


a = gets.chomp

