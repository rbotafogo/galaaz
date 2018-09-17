# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

diamonds = ~:diamonds

R.awt

print diamonds.ggplot(E.aes(:cut, :color)) +
      R.geom_jitter(E.aes(color: :cut), size: 0.5)

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
