---
title: "gKnit - Ruby and R Knitting with Galaaz in GraalVM"
author: "Rodrigo Botafogo"
tags: [Galaaz, Ruby, R, TruffleRuby, FastR, GraalVM, knitr]
date: "19 October 2018"
output:
  html_document:
    self_contained: true
    keep_md: true
  pdf_document:
    includes:
      in_header: ["../../sty/galaaz.sty"]
    number_sections: yes
---



# Introduction



```r
# load package and data
library(ggplot2)
data(mpg, package="ggplot2")
# mpg <- read.csv("http://goo.gl/uEeRGu")

mpg_select <- mpg[mpg$manufacturer %in% c("audi", "ford", "honda", "hyundai"), ]

# Scatterplot
theme_set(theme_bw())  # pre-set the bw theme.
g <- ggplot(mpg_select, aes(displ, cty)) + 
  labs(subtitle="mpg: Displacement vs City Mileage",
       title="Bubble chart")

g + geom_jitter(aes(col=manufacturer, size=hwy)) + 
  geom_smooth(aes(col=manufacturer), method="lm", se=F)
```

![](/home/rbotafogo/desenv/galaaz/blogs/dev/dev_files/figure-html/bubble-1.png)<!-- -->

### Plotting


```
## require 'ggplot'
## 
## R.theme_set R.theme_bw
## 
## # Data Prep
## mtcars = ~:mtcars
## mtcars.car_name = R.rownames(:mtcars)
## # compute normalized mpg 
## mtcars.mpg_z = ((mtcars.mpg - mtcars.mpg.mean)/mtcars.mpg.sd).round 2
## mtcars.mpg_type = mtcars.mpg_z < 0 ? "below" : "above"
## mtcars = mtcars[mtcars.mpg_z.order, :all]
## # convert to factor to retain sorted order in plot
## mtcars.car_name = mtcars.car_name.factor levels: mtcars.car_name
## 
## # Diverging Barcharts
## gg = mtcars.ggplot(E.aes(x: :car_name, y: :mpg_z, label: :mpg_z)) + 
##      R.geom_bar(E.aes(fill: :mpg_type), stat: 'identity',  width: 0.5) +
##      R.scale_fill_manual(name: "Mileage", 
##                          labels: R.c("Above Average", "Below Average"), 
##                          values: R.c("above": "#00ba38", "below": "#f8766d")) + 
##      R.labs(subtitle: "Normalised mileage from 'mtcars'", 
##             title: "Diverging Bars") + 
##      R.coord_flip()
## 
## print gg
```

