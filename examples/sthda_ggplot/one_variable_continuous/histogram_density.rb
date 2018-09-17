# coding: utf-8

if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

R.set__seed(1234)
wdata = R.data__frame(
  sex: R.c("F", "M").rep(each: 200).factor,
  weight: R.c(R.rnorm(200, 55), R.rnorm(200,58)))
puts wdata.head

R.awt

# Histogram  plot
# Change histogram fill color by group (sex)
wdata.qplot(:weight, geom: "histogram", fill: :sex)

sleep(2)
R.grid__newpage

# Density plot
# Change density plot line color by group (sex)
# change line type
wdata.qplot(:weight, geom: "density", color: :sex,
            linetype: :sex)

sleep(2)
R.grid__newpage

# removes the window and creates a new one
R.dev__off

