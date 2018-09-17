# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

tooth_growth = ~:ToothGrowth
tooth_growth.dose = tooth_growth.dose.as__factor
e = tooth_growth.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Default plot
print e + R.geom_dotplot(binaxis: "y", stackdir: "center")

sleep(2)
R.grid__newpage

# Dot plot with mean points (+/- SD)
# stat_summary requires library Hmisc that does not yet install in
# graalvm
# print e + R.geom_dotplot(binaxis: "y", stackdir: "center") + 
#      R.stat_summary(fun__data: "mean_sdl",  fun__args: E.list(mult: 1), 
#                     geom: "pointrange", color: "red")

sleep(2)
R.grid__newpage

# Combine with box plot
print e + R.geom_boxplot + 
      R.geom_dotplot(binaxis: "y", stackdir: "center") 
  
sleep(2)
R.grid__newpage

# Add violin plot
print e + R.geom_violin(trim: false) +
      R.geom_dotplot(binaxis: 'y', stackdir: 'center')

sleep(2)
R.grid__newpage

# Color and fill by group (dose) 
print e + R.geom_dotplot(E.aes(color: :dose, fill: :dose), 
                         binaxis: "y", stackdir: "center")

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
