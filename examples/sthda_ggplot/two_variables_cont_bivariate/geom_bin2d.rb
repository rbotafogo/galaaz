# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

diamonds = ~:diamonds
c = diamonds.ggplot(E.aes(:carat, :price))

R.awt

# Default plot 
print c + R.geom_bin2d


sleep(2)
R.grid__newpage

# Change the number of bins
print c + R.geom_bin2d(bins: 15)


sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window
R.dev__off
