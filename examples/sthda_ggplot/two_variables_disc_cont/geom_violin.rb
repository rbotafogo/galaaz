# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

# Package Hmisc does not yet install on graalvm because of
# problems with package data.table
# Polyglot.eval("R", "library('Hmisc')")

tooth_growth = ~:ToothGrowth
tooth_growth.dose = tooth_growth.dose.as__factor
e = tooth_growth.ggplot(E.aes(x: :dose, y: :len))

R.awt

# Default plot
print e + R.geom_violin(trim: false)

sleep(2)
R.grid__newpage

# violin plot with mean points (+/- SD)
# R.stat_summary requires Hmisc
print e + R.geom_violin(trim: false) + 
      R.stat_summary(fun__data: "mean_sdl",  fun__args: E.list(mult: 1), 
                     geom: "pointrange", color: "red")

# sleep(2)
# R.grid__newpage

# Combine with box plot
print e + R.geom_violin(trim: false) + 
      R.geom_boxplot(width: 0.2)

sleep(2)
R.grid__newpage

# Color by group (dose) 
print e + R.geom_violin(E.aes(color: :dose), trim: false)

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
