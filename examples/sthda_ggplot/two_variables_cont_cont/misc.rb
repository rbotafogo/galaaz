# coding: utf-8
if (!$CONFIG)
  require '../../../config' 
  require 'cantata'
end

Polyglot.eval("R", "library('quantreg')")

R.awt

# geom_quantile(): Add quantile lines from a quantile regression
print R.ggplot(~:mpg, E.aes(:cty, :hwy)) +
      R.geom_point + R.geom_quantile +
      R.theme_minimal


sleep(2)
R.grid__newpage

print R.ggplot(~:mpg, E.aes(:cty, :hwy)) +
      R.geom_point + R.stat_quantile(quantiles: R.c(0.25, 0.5, 0.75))

sleep(2)
R.grid__newpage

# geom_rug(): Add marginal rug to scatter plots
# Add marginal rugs using faithful data

print (~:faithful).ggplot(E.aes(x: :eruptions, y: :waiting)) +
      R.geom_point + R.geom_rug

sleep(2)
R.grid__newpage

# geom_jitter(): Jitter points to reduce overplotting

plot = (~:mpg).ggplot(E.aes(:displ, :hwy))

# Default scatter plot
plot = plot + R.geom_point

# Use jitter to reduce overplotting
plot = plot + R.geom_jitter(
         position: R.position_jitter(width: 0.5, height: 0.5))
print plot

sleep(2)
R.grid__newpage

#
mtcars = ~:mtcars
mtcars.cyl = R.as__factor(mtcars.cyl)
b = mtcars.ggplot(E.aes(x: :wt, y: :mpg))

print b + R.geom_text(E.aes(label: R.rownames(mtcars)))

sleep(2)
R.grid__newpage

# a = gets.chomp

# removes the window
R.dev__off
