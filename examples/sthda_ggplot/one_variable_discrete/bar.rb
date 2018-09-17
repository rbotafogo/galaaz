# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

mpg = ~:mpg
b = R.ggplot(mpg, E.aes(:fl))

R.awt

# Basic plot
print b + R.geom_bar

sleep(2)
R.grid__newpage

# Change fill color
print b + R.geom_bar(fill: "steelblue", color: "steelblue") +
      R.theme_minimal

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window and creates a new one
R.dev__off




