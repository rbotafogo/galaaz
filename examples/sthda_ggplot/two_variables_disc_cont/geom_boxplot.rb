# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

tooth_growth = R.ToothGrowth
tooth_growth.dose = tooth_growth.dose.as__factor
e = tooth_growth.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Default plot
print e + R.geom_boxplot('')

sleep(2)
R.grid__newpage

# Notched box plot
print e + R.geom_boxplot(notch: true)

sleep(2)
R.grid__newpage

# Color by group (dose)
print e + R.geom_boxplot(E.aes(color: :dose))

sleep(2)
R.grid__newpage

# Change fill color by group (dose)
print e + R.geom_boxplot(E.aes(fill: :dose))

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off('')
