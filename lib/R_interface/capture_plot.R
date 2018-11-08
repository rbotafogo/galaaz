#" Capture snapshot of current device.
#"
#" There's currently no way to capture when a graphics device changes,
#" except to check its contents after the evaluation of every expression.
#" This means that only the last plot of a series will be captured.
#"
#" @return \code{NULL} if plot is blank or unchanged, otherwise the output of
#"   \code{\link[grDevices]{recordPlot}}.
_plot_snapshot = function() {
    evaluate:::plot_snapshot()
}

# Function accessible from Galaaz to call non-exported knitr:::chunk_device function
_ck_dv = function(width, height, record = TRUE, dev, dev.args, dpi, options, 
                  tmp = tempfile()) {
    knitr:::chunk_device(width, height, record, dev, dev.args, dpi, options, tmp)
}

# Function to guess the extension name of a file based on the device type
_dev2ext = function(x) {
    knitr:::dev2ext(x)
}

_save_plot = function(plot, name, dev, width, height, ext, dpi, options) {
    print(options)
    knitr:::save_plot(plot, name, dev, width, height, ext, dpi, options)
}
