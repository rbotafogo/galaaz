# Function accessible from Galaaz to call non-exported knitr:::chunk_device function
_ck_dv = function(width, height, record = TRUE, dev, dev.args, dpi, options, 
                  tmp = tempfile()) {
    knitr:::chunk_device(width, height, record, dev, dev.args, dpi, options, tmp)
}

# Function to guess the extension name of a file based on the device type
knitr_dev2ext = function(x) {
    knitr:::dev2ext(x)
}

knitr_save_plot = function(plot, name, dev, width, height, ext, dpi, options) {
    print(options)
    knitr:::save_plot(plot, name, dev, width, height, ext, dpi, options)
}

knitr_opts_chunk = function() {
    knitr:::opts_chunk
}

evaluate_plot_snapshot = function() {
    evaluate:::plot_snapshot()
}
