# define the ruby engine for processing Ruby chunks in
# rmarkdown
eng_ruby = function(options) {
    block_code = paste(options$code, collapse = "\\n");
    code = paste0("GalaazUtil.exec_ruby(", 
                  sQuote(block_code), 
                  ")"
                  );
    
    keep = options$fig.keep
    keep.idx = NULL
    if (is.numeric(keep)) {
        keep.idx = keep
        keep = "index"
    }
    
    tmp.fig = tempfile(); on.exit(unlink(tmp.fig), add = TRUE)
    
                                        # open a device to record plots
    if (knitr:::chunk_device(options$fig.width[1L], options$fig.height[1L], keep != "none",
                             options$dev, options$dev.args, options$dpi, options, tmp.fig)) {
                                        # preserve par() settings from the last code chunk
        if (keep.pars <- opts_knit$get("global.par"))
            par2(opts_knit$get("global.pars"))
        knitr:::showtext(options$fig.showtext)  # showtext support
        dv = dev.cur()
        on.exit({
            if (keep.pars) opts_knit$set(global.pars = par(no.readonly = TRUE))
            dev.off(dv)
        }, add = TRUE)
    }
    
                                        # guess plot file type if it is NULL
    if (keep != "none" && is.null(options$fig.ext))
        options$fig.ext = knitr:::dev2ext(options$dev)
    
    res = eval.polyglot("ruby", code)
    
                                        # rearrange locations of figures
    figs = find_recordedplot(res)
    if (length(figs) && any(figs)) {
        if (keep == 'none') {
            res = res[!figs] # remove all
        } else {
            if (options$fig.show == 'hold') res = c(res[!figs], res[figs]) # move to the end
            figs = find_recordedplot(res)
            if (length(figs) && sum(figs) > 1) {
                if (keep %in% c('first', 'last')) {
                    res = res[-(if (keep == 'last') head else tail)(which(figs), -1L)]
                } else {
                                        # keep only selected
                    if (keep == 'index') res = res[which(figs)[keep.idx]]
                                        # merge low-level plotting changes
                    if (keep == 'high') res = merge_low_plot(res, figs)
                }
            }
        }
    }
    engine_output(options, block_code, res)
}

knit_engines$set(ruby = eng_ruby)
