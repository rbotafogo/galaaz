The examples presented in this directory are extracted from:

http://www.sthda.com/english/wiki/be-awesome-in-ggplot2-a-practical-guide-to-be-highly-effective-r-software-and-data-visualization

# Basics

ggplot2 is a powerful and a flexible R package, implemented by Hadley Wickham, for
producing elegant graphics. The gg in ggplot2 means Grammar of Graphics, a graphic concept
which describes plots by using a “grammar”.

According to ggplot2 concept, a plot can be divided into different fundamental parts:
Plot = data + Aesthetics + Geometry.

The principal components of every plot can be defined as follow:

 * data is a data frame
 * Aesthetics is used to indicate x and y variables. It can also be used to control the
   color, the size or the shape of points, the height of bars, etc…..
 * Geometry corresponds to the type of graphics (histogram, box plot, line plot,
   density plot, dot plot, ….)

Two main functions, for creating plots, are available in ggplot2 package : a qplot() and
ggplot() functions.

  * qplot() is a quick plot function which is easy to use for simple plots.
  * The ggplot() function is more flexible and robust than qplot for building a plot piece by piece.

The generated plot can be kept as a variable and then printed at any time using the function
print().

After creating plots, two other important functions are:

  * last_plot(), which returns the last plot to be modified
  * ggsave(“plot.png”, width = 5, height = 5), which saves the last plot in the current
    working directory.

This document describes how to create and customize different types of graphs using ggplot2.
Many examples of code and graphics are provided.
