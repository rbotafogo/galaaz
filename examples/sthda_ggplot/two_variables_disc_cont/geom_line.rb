# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

df = R.data__frame(supp: R.rep(R.c("VC", "OJ"), each: 3),
                   dose: R.rep(R.c("D0.5", "D1", "D2"), 2),
                   len: R.c(6.8, 15, 33, 4.2, 10, 29.5))
puts df.head


R.awt

# Change line types by groups (supp)
print df.ggplot(E.aes(x: :dose, y: :len, group: :supp)) +
      R.geom_line(E.aes(linetype: :supp)) +
      R.geom_point('')

sleep(2)
R.grid__newpage

# Change line types, point shapes and colors
print df.ggplot(E.aes(x: :dose, y: :len, group: :supp)) +
      R.geom_line(E.aes(linetype: :supp, color: :supp)) +
      R.geom_point(E.aes(shape: :supp, color: :supp))

sleep(2)
R.grid__newpage


# a = gets.chomp

# removes the window
R.dev__off('')
