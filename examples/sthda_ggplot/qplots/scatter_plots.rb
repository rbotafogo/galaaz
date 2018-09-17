# coding: utf-8
if (!$CONFIG)
  require '../../config' 
  require 'cantata'
end

# Load the data
mtcars = ~:mtcars
df = mtcars[:all, R.c("mpg", "cyl", "wt")]

# Convert cyl to a factor variable
df.cyl = R.as__factor(df.cyl)
puts df.head

R.awt

# Basic scatter plot
print R.qplot(x: :mpg, y: :wt, data: df, geom: "point")

# wait 2 seconds for the next plog
sleep(2)
# clear the page
R.grid__newpage

# Scatter plot with smoothed line
# Calling qplot on a dataframe does not require the data: parameter
# nor print
df.qplot(:mpg, :wt, geom: R.c("point", "smooth"))

# wait 2 seconds for the next plog
sleep(2)
# clear the page
R.grid__newpage

# The following code will change the color and the shape of points by groups.
# The column cyl will be used as grouping variable. In other words, the color
# and the shape of points will be changed by the levels of cyl.
df.qplot(:mpg, :wt, colour: :cyl, shape: :cyl)


# wait 2 seconds for the next plog
sleep(2)
# clear the page
R.grid__newpage

# removes the window and creates a new one
R.dev__off
