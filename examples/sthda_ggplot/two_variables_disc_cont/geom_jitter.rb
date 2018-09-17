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
print e + R.geom_jitter(position: R.position_jitter(0.2))

sleep(2)
R.grid__newpage

# Strip charts with mean points (+/- SD)
print e + R.geom_jitter(position: R.position_jitter(0.2)) + 
      R.stat_summary(fun__data: "mean_sdl",  fun__args: R.list(mult: 1), 
                     geom: "pointrange", color: "red")

sleep(2)
R.grid__newpage

# Combine with box plot
print e + R.geom_jitter(position: R.position_jitter(0.2)) + 
      R.geom_dotplot(binaxis: "y", stackdir: "center") 

sleep(2)
R.grid__newpage

# Add violin plot
print e + R.geom_violin(trim: false) +
      R.geom_jitter(position: R.position_jitter(0.2))
  

sleep(2)
R.grid__newpage

# Change color and shape by group (dose) 
print e + R.geom_jitter(E.aes(color: :dose, shape: :dose),
                        position: R.position_jitter(0.2))

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
