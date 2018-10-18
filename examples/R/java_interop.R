library(grid)
openJavaWindow <- function () {
   # create image and register graphics
   imageClass <- java.type('java.awt.image.BufferedImage')
   image <- new(imageClass, 450, 450, imageClass$TYPE_INT_RGB);
   graphics <- image$getGraphics()
   graphics$setBackground(java.type('java.awt.Color')$white);
   grDevices:::awt(image$getWidth(), image$getHeight(), graphics)

   # draw image
   grid.newpage()
   pushViewport(plotViewport(margins = c(5.1, 4.1, 4.1, 2.1)))
   grid.xaxis(); grid.yaxis()
   grid.points(x = runif(10, 0, 1), y = runif(10, 0, 1),
        size = unit(0.01, "npc"))

   # open frame with image
   imageIcon <- new("javax.swing.ImageIcon", image)
   label <- new("javax.swing.JLabel", imageIcon)
   panel <- new("javax.swing.JPanel")
   panel$add(label)
   frame <- new("javax.swing.JFrame")
   frame$setMinimumSize(new("java.awt.Dimension",
                image$getWidth(), image$getHeight()))
   frame$add(panel)
   frame$setVisible(T)
   while (frame$isVisible()) Sys.sleep(1)
}
openJavaWindow()
