require 'galaaz'
require 'ggplot'

 # load package and data
R.options(scipen: 999)  # turn-off scientific notation like 1e+48
R.theme_set(R.theme_bw)  # pre-set the bw theme.

midwest = ~:midwest
 # midwest <- read.csv("http://goo.gl/G1K41K")  # bkup data source

R.awt

 # Scatterplot
gg = midwest.ggplot(E.aes(x: :area, y: :poptotal)) + 
     R.geom_point(E.aes(col: :state, size: :popdensity)) + 
     R.geom_smooth(method: "loess", se: false) + 
     R.xlim(R.c(0, 0.1)) + 
     R.ylim(R.c(0, 500000)) + 
     R.labs(subtitle: "Area Vs Population", 
            y: "Population", 
            x: "Area", 
            title: "Scatterplot", 
            caption: "Source: midwest")

puts gg

