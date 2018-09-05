# coding: utf-8
require '../config'
require 'cantata'

# Polyglot.eval("R", "library('MASS')")
# Polyglot.eval("R", "library('ISLR')")
R.library('MASS')
R.library('ISLR')

boston = R.Boston

puts boston.names

boston_lm = R.lm(:medv =~ :lstat, data: boston)
# puts boston_lm.str
# puts boston_lm.summary
puts boston_lm.names
puts boston_lm.coef
puts boston_lm.confint
conf = R.predict(boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))), interval: "confidence")
puts conf
pred = R.predict(boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))), interval: "prediction")
puts pred
                 
# b = boston.ggplot(E.aes(x: :lstat, y: :medv))
   
R.awt
R.jpeg("ScatterPlot_lstat_medv.jpg")
puts R.qplot(boston.lstat, boston.medv, col: "red")
R.grid__newpage('')

R.jpeg("ScatterPlot_pred_residuals.jpg")
puts R.qplot(R.predict(boston_lm), R.residuals(boston_lm))
# sleep(5)
R.grid__newpage('')


# change the color and the point 
# by the levels of cyl variable
# print b + R.geom_point(E.aes(color: "red", shape: :cyl)) 
          
=begin
fix(Boston)
names(Boston)
lm.fit=lm(medv~lstat)
lm.fit=lm(medv~lstat,data=Boston)
attach(Boston)
lm.fit=lm(medv~lstat)
lm.fit

plot(lstat,medv)
abline(lm.fit)
abline(lm.fit,lwd=3)
abline(lm.fit,lwd=3,col="red")
plot(lstat,medv,col="red")
plot(lstat,medv,pch=20)
plot(lstat,medv,pch="+")
plot(1:20,1:20,pch=1:20)
par(mfrow=c(2,2))
plot(lm.fit)
plot(predict(lm.fit), residuals(lm.fit))
plot(predict(lm.fit), rstudent(lm.fit))
plot(hatvalues(lm.fit))
which.max(hatvalues(lm.fit))
=end
