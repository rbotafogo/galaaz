# Minimal device helpers for R::Device (no knitr or evaluate dependency).
# Captures current graphics device with base R recordPlot(); replay() redraws it.
evaluate_plot_snapshot = function() {
  recordPlot()
}

galaaz_save_plot = function(plot, name, dev, width, height, ext, dpi) {
  f <- paste0(name, ".", ext)
  if (dev == "png") {
    png(f, width = width * dpi, height = height * dpi, res = dpi)
  } else {
    svg(f, width = width, height = height)
  }
  if (inherits(plot, "recordedplot")) {
    replayPlot(plot)
  } else {
    print(plot)
  }
  dev.off()
}
