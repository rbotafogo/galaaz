# coding: utf-8
if (!$CONFIG)
  require '../../config' 
  require 'cantata'
end

R.set__seed(1234)
wdata = R.data__frame(
  sex: R.c("F", "M").rep(each: 200).factor,
  weight: R.c(R.rnorm(200, 55), R.rnorm(200,58)))
puts wdata.head

R.awt

# Basic box plot from data frame
wdata.qplot(:sex, :weight, geom: "boxplot", fill: :sex)

sleep(2)
R.grid__newpage

# Violin plot
wdata.qplot(:sex, :weight, geom: "violin")

sleep(2)
R.grid__newpage

# Dot plot
wdata.qplot(:sex, :weight, geom: "dotplot", stackdir: "center",
            binaxis: "y", dotsize: 0.5)

sleep(2)
R.grid__newpage

# removes the window and creates a new one
R.dev__off('')
