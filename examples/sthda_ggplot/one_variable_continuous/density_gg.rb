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

# Use geometry function
print wdata.ggplot(E.aes(x: :weight)) + R.geom_density('')

sleep(2)
R.grid__newpage

# OR use stat function
print wdata.ggplot(E.aes(x: :weight)) + R.stat_density('')


sleep(2)
R.grid__newpage

# a = gets.chomp


# removes the window and creates a new one
R.dev__off('')
