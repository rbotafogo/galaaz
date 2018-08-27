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

# We start by creating a plot, named 'a', that we’ll finish next by adding layers
a = wdata.ggplot(E.aes(x: :weight))

R.awt

# Basic plot
print a + R.geom_area(stat: "bin")

sleep(2)
R.grid__newpage

# change fill colors by sex
print a + R.geom_area(E.aes(fill: :sex),
                      stat: "bin", alpha: 0.6) +
      R.theme_classic('')


sleep(2)
R.grid__newpage

print a + R.geom_area(E.aes_string(y: "..density.."), stat: "bin")
# a = gets.chomp


# removes the window and creates a new one
R.dev__off('')
