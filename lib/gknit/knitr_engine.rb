# -*- coding: utf-8 -*-

##########################################################################################
# @author Rodrigo Botafogo
#
# Copyright © 2018 Rodrigo Botafogo. All Rights Reserved. Permission to use, copy, modify, 
# and distribute this software and its documentation, without fee and without a signed 
# licensing agreement, is hereby granted, provided that the above copyright notice, this 
# paragraph and the following two paragraphs appear in all copies, modifications, and 
# distributions.
#
# IN NO EVENT SHALL RODRIGO BOTAFOGO BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, 
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF 
# THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RODRIGO BOTAFOGO HAS BEEN ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# RODRIGO BOTAFOGO SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE 
# SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED HEREUNDER IS PROVIDED "AS IS". 
# RODRIGO BOTAFOGO HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
# OR MODIFICATIONS.
##########################################################################################

require 'singleton'
require 'fileutils'
require 'pathname'

# Load these before anything else to ensure bridge is initialized and libraries are present
R.install_and_loads('knitr', 'rmarkdown')

# Source the R-side include engine wrapper that reads files before calling Ruby
# This avoids callback deadlock and escaping issues with file content
dir = File.dirname(File.expand_path(__FILE__))
include_engine_r = File.join(dir, '..', 'R_interface', 'include_engine.R')
if File.exist?(include_engine_r)
  R.bridge.eval_r("source('#{include_engine_r}')")
end

class KnitrEngine

  attr_reader :options

  #
  # Code Evaluation
  #
  
  # eval: (TRUE; logical) whether to evaluate the code chunk
  attr_reader :eval

  #
  # Text Results
  #
  
  # echo: (TRUE; logical) whether to include Ruby source code in
  # the output file
  attr_reader :echo

  # results: ('markup'; character) takes these possible values
  # markup: mark up the results using the output hook, e.g. put results in a
  #   special LaTeX environment
  # asis: output as-is, i.e., write raw results from R into the output document
  # hold: hold all the output pieces and push them to the end of a chunk
  # hide (or FALSE): hide results; this option only applies to normal R
  #   output (not warnings, messages or errors)
  attr_reader :results

  # collapse: (FALSE; logical; applies to Markdown output only) whether to,
  # if possible, collapse all the source and output blocks from one code chunk
  # into a single block (by default, they are written to separate <pre></pre> blocks)
  attr_reader :collapse

  # warning: (TRUE; logical) whether to preserve warnings (produced by warning())
  # in the output like we run R code in a terminal (if FALSE, all warnings will
  # be printed in the console instead of the output document); it can also
  # take numeric values as indices to select a subset of warnings to
  # include in the output
  attr_reader :warning

  # error: (TRUE; logical) whether to preserve errors (from stop()); by default,
  # the evaluation will not stop even in case of errors!! if we want R to stop
  # on errors, we need to set this option to FALSE
  # when the chunk option include = FALSE, error knitr will stop on error,
  # because it is easy to overlook potential errors in this case
  attr_reader :error

  # message: (TRUE; logical) whether to preserve messages emitted by
  # message() (similar to warning)
  attr_reader :message

  # split: (FALSE; logical) whether to split the output from R into separate
  # files and include them into LaTeX by \input{} or HTML by <iframe></iframe>;
  # this option only works for .Rnw, .Rtex, and .Rhtml documents
  # (it does not work for R Markdown)
  attr_reader :split

  # include: (TRUE; logical) whether to include the chunk output in the final
  # output document; if include=FALSE, nothing will be written into the output
  # document, but the code is still evaluated and plot files are generated if
  # there are any plots in the chunk, so you can manually insert figures;
  # note this is the only chunk option that is not cached, i.e., changing it
  # will not invalidate the cache
  attr_reader :include

  # strip.white: (TRUE; logical) whether to remove the white lines in the
  # beginning or end of a source chunk in the output
  attr_reader :strip__white

  # render: (knitr::knit_print; function(x, options, ...)) the function which
  # formats the result of the chunk for the final output format. The function
  # is given the chunk result as first argument and the list of chunk options
  # as a named argument options. If the function contains further arguments
  # which match names of chunk options, they are filled with the respective
  # values. The function is expected to return one string which is then
  # rendered appropriately for the current output format. For more information,
  # invoke the help about custom chunk rendering: Invoke in R:
  # vignette('knit_print', package = 'knitr') and ?knitr::knit_print.
  attr_reader :render

  # class.output: (NULL; character) useful for HTML output, appends classes
  # that can be used in conjunction with css, so you can apply custom formatting.
  attr_reader :class__output

  #
  # Code Decoration
  #
  
  # tidy: (FALSE) whether to reformat the R code; other possible values are:
  #   * TRUE (equivalent to 'formatR'): use formatR::tidy_source() to reformat the code;
  #   * 'styler': use styler::style_text() to reformat the code;
  #   * a custom function of the form function(code, ...) {} to return the reformatted code;
  #   * if reformatting failed, the original R code will not be changed (with a warning)
  attr_reader :tidy
  
  # tidy.opts: (NULL; list) a list of options to be passed to the function
  # determined by the tidy option, e.g.,
  # tidy.opts = list(blank = FALSE, width.cutoff = 60) for tidy = 'formatR'
  # to remove blank lines and set the approximate line width to be 60
  attr_reader :tidy__opts
  
  # prompt: (FALSE; logical) whether to add the prompt characters in the R
  # code (see prompt and continue in ?base::options; note that adding prompts
  # can make it difficult for readers to copy R code from the output, so
  # prompt=FALSE may be a better choice
  #  this option may not work well when the chunk option engine is not R (#1274)
  attr_reader :prompt
  
  # comment: ('##'; character) the prefix to be put before source code output;
  # default is to comment out the output by ##, which is good for readers to copy
  # R source code since output is masked in comments
  # (set comment=NA to disable this feature)
  attr_reader :comment
  
  # highlight: (TRUE; logical) whether to highlight the source code
  # (it is FALSE by default if the output is Sweave or listings)
  attr_reader :highlight
  
  # size: ('normalsize'; character) font size for the default LaTeX
  # output (see ?highlight in the highlight package for a list of possible values)
  attr_reader :size
  
  # background: ('#F7F7F7'; character or numeric) background color of chunks
  # in LaTeX output (passed to the LaTeX package framed); the color model is rgb;
  # it can be either a numeric vector of length 3, with each element between 0 and 1
  # to denote red, green and blue, or any built-in color in R like red or
  # springgreen3 (see colors() for a full list), or a hex string like #FFFF00,
  # or an integer (all these colors will be converted to the RGB model;
  # see ?col2rgb for details)
  attr_reader :background
  
  # class.source: (NULL; character) useful for HTML output, appends classes that
  # can be used in conjunction with css, so you can apply custom formatting.
  attr_reader :class__source

  #
  # Plots
  #

  # fig.path: ('figure/'; character) prefix to be used for figure filenames
  # (fig.path and chunk labels are concatenated to make filenames); it may contain
  # a directory like figure/prefix- (will be created if it does not exist);
  # this path is relative to the current working directory; if the prefix ends in
  # a trailing slash, e.g. output/figures/, figures will be saved in the specified
  # directory without any changes to filename prefix, thus providing a relative
  # filepath alternative to the package-level option base.dir
  attr_reader :fig__path
  attr_reader :fig__filename
  
  # fig.keep: ('high'; character) how plots in chunks should be kept; it takes
  # five possible character values or a numeric vector
  # (see the end of this section for an example)
  # * high: only keep high-level plots (merge low-level changes into high-level plots);
  # * none: discard all plots;
  # * all: keep all plots (low-level plot changes may produce new plots)
  # * first: only keep the first plot
  # * last: only keep the last plot
  # if set to a numeric vector: interpret value as index of (low-level) plots to keep
  attr_reader :fig__keep
  
  # fig.show: ('asis'; character) how to show/arrange the plots; four
  # possible values are
  # * asis: show plots exactly in places where they were generated
  #     (as if the code were run in an R terminal);
  # * hold: hold all plots and output them in the very end of a code chunk;
  # * animate: wrap all plots into an animation if there are mutiple plots in a chunk;
  # * hide: generate plot files but hide them in the output document
  attr_reader :fig__show
  
  # dev: ('pdf' for LaTeX output and 'png' for HTML/markdown; character) the function
  #   name which will be used as a graphical device to record plots; for the convenience
  #   of usage, this package has included all the graphics devices in base R as well as
  #   those in Cairo, cairoDevice and tikzDevice, e.g. if we set dev='CairoPDF', the
  #   function with the same name in the Cairo package will be used for graphics output;
  #   if none of the 20 built-in devices is appropriate, we can still provide yet another
  #   name as long as it is a legal function name which can record plots
  #   (it must be of the form function(filename, width, height)); note the units for
  #   images are always inches (even for bitmap devices, in which DPI is used to convert
  #   between pixels and inches); currently available devices are bmp, postscript, pdf,
  #   png, svg, jpeg, pictex, tiff, win.metafile, cairo_pdf, cairo_ps, CairoJPEG,
  #   CairoPNG, CairoPS, CairoPDF, CairoSVG, CairoTIFF, Cairo_pdf, Cairo_png, Cairo_ps,
  #   Cairo_svg, tikz and a series of quartz devices including quartz_pdf, quartz_png,
  #   quartz_jpeg, quartz_tiff, quartz_gif, quartz_psd, quartz_bmp which are just
  #   wrappers to the function quartz() with different file types
  # * the options dev, fig.ext, fig.width, fig.height and dpi can be vectors
  #   (shorter ones will be recycled), e.g. <<foo, dev=c('pdf', 'png')>>= creates
  #   two files for the same plot: foo.pdf and foo.png
  attr_reader :dev

  # dev.args: (NULL) more arguments to be passed to the device, e.g.
  # dev.args=list(bg='yellow', pointsize=10); note this depends on the specific
  # device (see the device documentation); when dev has multiple elements, dev.args
  # can be a list of lists of arguments with each list of arguments to be passed to
  # each single device, e.g. <<dev=c('pdf', 'tiff'),
  # dev.args=list(pdf = list(colormodel = 'cmyk', useDingats = TRUE),
  #               tiff = list(compression = 'lzw'))>>=
  attr_reader :dev__args
  
  # fig.ext: (NULL; character) file extension of the figure output
  # (if NULL, it will be derived from the graphical device; see
  # knitr:::auto_exts for details)
  attr_reader :fig__ext
  
  # dpi: (72; numeric) the DPI (dots per inch) for bitmap devices (dpi * inches = pixels)
  attr_reader :dpi
  
  # fig.width, fig.height: (both are 7; numeric) width and height of the plot,
  # to be used in the graphics device (in inches) and have to be numeric
  attr_reader :fig__width
  attr_reader :fig__height
  
  # fig.asp: (NULL; numeric) the aspect ratio of the plot, i.e. the ratio of
  # height/width; when fig.asp is specified, the height of a plot (the chunk option
  # fig.height) is calculated from fig.width * fig.asp
  attr_reader :fig__asp
  
  # fig.dim: (NULL; numeric) if a numeric vector of length 2, it gives fig.width
  # and fig.height, e.g., fig.dim = c(5, 7) is a shorthand of fig.width = 5,
  # fig.height = 7; if both fig.asp and fig.dim are provided, fig.asp will
  # be ignored (with a warning)
  attr_reader :fig__dim
  
  # out.width, out.height: (NULL; character) width and height of the plot in
  # the final output file (can be different with its real fig.width and fig.height,
  # i.e. plots can be scaled in the output document); depending on the output format,
  # these two options can take flexible values, e.g. for LaTeX output, they
  # can be .8\\linewidth, 3in or 8cm and for HTML, they may be 300px (do not have to
  # be in inches like fig.width and fig.height; backslashes must be escaped as \\);
  # for LaTeX output, the default value for out.width will be changed to \\maxwidth
  # which is defined here out.width can also be a percentage, e.g. '40%' will be
  # translated to 0.4\linewidth when the output format is LaTeX
  attr_reader :out__width
  attr_reader :out__height

  # out.extra: (NULL; character) extra options for figures, e.g. out.extra='angle=90'
  # in LaTeX output will rotate the figure by 90 degrees; it can be an arbitrary
  # string, e.g. you can write multiple figure options in this option; it also applies
  # to HTML images (extra options will be written into the <img /> tag, e.g.
  # out.extra='style="display:block;"')
  attr_reader :out__extra
  
  # fig.retina: (1; numeric) this option only applies to HTML output; for Retina
  # displays, setting this option to a ratio (usually 2) will change the chunk
  # option dpi to dpi * fig.retina, and out.width to fig.width * dpi / fig.retina
  # internally; for example, the physical size of an image is doubled and its display
  # size is halved when fig.retina = 2
  attr_reader :fig__retina
  
  # resize.width, resize.height: (NULL; character) the width and height to be used
  # in \resizebox{}{} in LaTeX; these two options are not needed unless you want to
  # resize tikz graphics because there is no natural way to do it; however, according
  # to tikzDevice authors, tikz graphics is not meant to be resized to maintain
  # consistency in style with other texts in LaTeX; if only one of them is NULL,
  # ! will be used (read the documentation of graphicx if you do not understand this)
  attr_reader :resize__width
  attr_reader :resize__height
  
  # fig.align: ('default'; character) alignment of figures in the output document
  # (possible values are left, right and center; default is not to make any
  # alignment adjustments); note that for Markdown output, forcing figure
  # alignments will lead to the HTML tag <img /> instead of the original Markdown
  # syntax ![](), because Markdown does not have native support for figure
  # alignments (see #611)
  attr_reader :fig__align
  
  # fig.env: ('figure') the LaTeX environment for figures, e.g. set
  # fig.env='marginfigure' to get \begin{marginfigure}
  attr_reader :fig__env
  
  # fig.cap: (NULL; character) figure caption to be used in a figure environment
  # in LaTeX (in \caption{}); if NULL or NA, it will be ignored, otherwise a
  # figure environment will be used for the plots in the chunk
  # (output in \begin{figure} and \end{figure})
  attr_reader :fig__cap
  
  # fig.scap: (NULL; character) short caption; if NULL, all the words before .
  # or ; or : will be used as a short caption; if NA, it will be ignored
  attr_reader :fig__scap
  
  # fig.lp: ('fig:'; character) label prefix for the figure label to be used
  # in \label{}; the actual label is made by concatenating this prefix and the
  # chunk label, e.g. the figure label for <<foo-plot>>= will be fig:foo-plot by default
  attr_reader :label
  attr_reader :fig__lp
  
  # fig.pos: (''; character) a character string for the figure position arrangement
  # to be used in \begin{figure}[fig.pos]
  attr_reader :fig__pos
  
  # fig.subcap: (NULL) captions for subfigures; when there are multiple plots in
  # a chunk, and neither fig.subcap nor fig.cap is NULL, \subfloat{} will be used
  # for individual plots (you need to add \usepackage{subfig} in the preamble);
  # see 067-graphics-options.Rnw for an example
  attr_reader :fig__subcap
  
  # fig.ncol: (NULL; integer) the number of columns of subfigures; see here for
  # examples (note that fig.ncol and fig.sep only work for LaTeX output)
  attr_reader :fig__ncol
  
  # fig.sep: (NULL; character) a character vector of separators to be inserted among
  # subfigures; when fig.ncol is specified, fig.sep defaults to a character vector
  # of which every N-th element is \newline (where N is the number of columns),
  # e.g., fig.ncol = 2 means
  # fig.sep = c('', '', '\\newline', '', '', '\\newline', '', ...)
  attr_reader :fig__sep
  
  # fig.process: (NULL) a function to post-process a figure file; it should take a
  # filename, and return a character string as the new source of the figure to be
  # inserted in the output
  attr_reader :fig__process
  
  # fig.showtext: (NULL) if TRUE, call showtext::showtext.begin() before drawing
  # plots; see the documentation of the showtext package for details
  attr_reader :fig__showtext
  
  # external: (TRUE; logical) whether to externalize tikz graphics (pre-compile
  # tikz graphics to PDF); it is only used for the tikz() device in the tikzDevice
  # package (i.e., when dev='tikz') and it can save time for LaTeX compilation
  attr_reader :external
  
  # sanitize: (FALSE; character) whether to sanitize tikz graphics (escape
  # special LaTeX characters); see documentation in the tikzDevice package
  attr_reader :sanitize

  attr_reader :keep

  #--------------------------------------------------------------------------------------
  # opens a device for plot recording.  Method chunk_device in knitr is not exported,
  # so it cannot yet be accessed by Galaaz.  Need to develop a local function that calls
  # the non-exported function.
  #--------------------------------------------------------------------------------------

  R::Support.eval(<<-GK_BOOT)

    # Bind on .GlobalEnv so Ruby exec_function("evaluate_plot_snapshot") / recordPlot / knitr
    # always resolve them (new bridge evaluates in a per-session env; plain '=' here can leave
    # helpers only in transient frames, so gknit never records ggplot output).
    .GlobalEnv$knitr_dev2ext <- function(x) {
        knitr:::dev2ext(x)
    }

    #" Capture snapshot of current device (base R recordPlot; same as galaaz_device.R).
    # g_simpleMessage: same signature as simpleMessage; transforms "; " to newlines then calls base::simpleMessage
    .GlobalEnv$g_simpleMessage <- function(message) {
        message <- gsub("; ", "; \n", message, fixed = TRUE)
        base::simpleMessage(message)
    }

    # g_simpleWarning: same signature as simpleWarning; transforms "; " to newlines then calls base::simpleWarning
    .GlobalEnv$g_simpleWarning <- function(message) {
        message <- gsub("; ", "; \n", message, fixed = TRUE)
        base::simpleWarning(message)
    }

    #" evaluate:::plot_snapshot() does not exist in the evaluate package, so use recordPlot().
    .GlobalEnv$evaluate_plot_snapshot <- function() {
        grDevices::recordPlot()
    }

    # Save a recorded plot to a file in one R call (open device, replayPlot, dev.off) so device state is consistent.
    .GlobalEnv$save_recorded_plot <- function(path, plot, width, height, dev, res, units) {
        if (dev == "png" || dev == "pdf") {
            if (dev == "png") do.call(grDevices::png, list(path, width = width, height = height, res = res, units = units))
            else do.call(grDevices::pdf, list(path, width = width, height = height))
            grDevices::replayPlot(plot)
            grDevices::dev.off()
        }
    }

    .GlobalEnv$knitr_wrap <- function(x, options) {
      knitr:::wrap(x, options)
    }

    assign("wrap.message", function(x, options) {
      knitr:::msg_wrap(paste("Message:\n", x$message, collapse = ''), 'message', options)
    }, envir = .GlobalEnv)

    # The showtext package, is able to support more font formats and more graphics
    # devices, and avoids using external software such as Ghostscript. showtext makes it
    # even easier to use various types of fonts (TrueType, OpenType, Type 1, web fonts,
    # etc.) in R graphs.
    .GlobalEnv$showtext <- function() {
      showtext::showtext_begin()
    }

    invisible(NULL)

  GK_BOOT

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def units
    opt_units = (@options[["units"]])
    (opt_units.is__null.unboxed_get(0)) ? "in" : opt_units
  end

  #--------------------------------------------------------------------------------------
  # Safely normalize scalar chunk option values that may come boxed from R.
  #--------------------------------------------------------------------------------------

  def scalar_option_string(opt)
    return opt.unboxed_get(0).to_s if opt.respond_to?(:unboxed_get)
    opt.to_s
  rescue StandardError
    opt.to_s
  end

  #--------------------------------------------------------------------------------------
  # Process the fig.keep chunk option
  # @param keep [String/Numeric] a string or a number.  If it is a string then it should
  #   be one of the following: 
  #   * high: only keep high-level plots (merge low-level changes into high-level plots);
  #   * none: discard all plots;
  #   * all: keep all plots (low-level plot changes may produce new plots)
  #   * first: only keep the first plot
  #   * last: only keep the last plot
  #   if set to a numeric vector: interpret value as index of (low-level) plots to keep
  #   In this case, set variable @keep to "index" and variable @keep_ind as the numeric
  #   index.
  #--------------------------------------------------------------------------------------

  def fig_keep
    @keep = @fig__keep
    @keep_idx = nil
    
    if (@keep.is__numeric.unboxed_get(0))
      @keep_idx = @keep
      @keep = "index"
    end
    
  end
  
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------

  def file_ext
    # guess plot file type if it is NULL
    # Use @fig__ext (already set from options['fig.ext']) to avoid calling R's fig.ext(options) which triggers invalid connection
    fig_ext_empty = @fig__ext.nil? || (@fig__ext.respond_to?(:to_s) && @fig__ext.to_s.strip.empty?)
    # NA from knitr "inherit" must not skip dev2ext (same as GalaazUtil.knitr_logical_trueish? for chunk options).
    keep_plots = GalaazUtil.knitr_logical_trueish?(((@keep != 'none') rescue nil))
    if keep_plots && fig_ext_empty
      @fig__ext = (R.knitr_dev2ext(@options).unboxed_get(0))
    end
  end

  #--------------------------------------------------------------------------------------
  # Process the chunk options
  #--------------------------------------------------------------------------------------
  
  def process_options(options)

    @options = options

    # Chunk options
    @label = (options['label'].unboxed_get(0))
    
    # Text results
    @eval = options[["eval"]] 
    @echo = GalaazUtil.knitr_option_trueish?(options, 'echo', default: true)
    @results = options['results'] 
    @collapse = options['collapse'] 
    @warning = options['warning'] 
    @error = options['error'] 
    @message = options['message'] 
    @split = options['split'] 
    @include = GalaazUtil.knitr_option_trueish?(options, 'include', default: true)
    @strip__white = options['strip.white'] 
    # @render = options['render'] # a function
    @class__output = options['class.output'] 
    
    # Code Decoration
    # @tidy = options['tidy'] 
    # @tidy__opts = options['tidy.opts']
    @prompt = options['prompt']  
    @comment = options['comment'] 
    @highlight = options['highlight'] 
    @size = options['size'] 
    @background = options['background'] 
    @class__source = options['class_source'] 
    
    # Plots - avoid unboxed_get in callback as it uses RESULT_FIFO which fails with "invalid connection"
    @fig__path = scalar_option_string(options['fig.path'])
    @fig__keep = options['fig.keep'] # can be a vector; use options['fig.keep'] not options.fig__keep to avoid R's fig.keep() which triggers invalid connection
    @fig__show = options['fig.show'] 
    @dev = options['dev'] 
    # @dev__args = options['dev.args'] # can be a vector
    @fig__ext = scalar_option_string(options['fig.ext'])
    @dpi = options['dpi'] 
    @fig__width = options['fig.width'] 
    @fig__height = options['fig.height'] 
    @fig__asp = options['fig.asp'] 
    # @fig__dim = options['fig.dim']  # vector with two elements
    @out__width = options['out.width'] 
    @out__height = options['out.height'] 
    @out__extra = options['out.extra'] 
    @fig__retina = options['fig.retina'] 
    @resize__width = options['resize.width'] 
    @resize__height = options['resize.height'] 
    @fig__align = options['fig.align'] 
    @fig__env = options['fig.env'] 
    @fig__cap = options['fig.cap'] 
    @fig__scap = options['fig.scap'] 
    @fig__lp = options['fig.lp'] 
    @fig__pos = options['fig.pos'] 
    @fig__subcap = options['fig.subcap'] 
    @fig__ncol = options['fig.ncol'] 
    # @fig__sep = options['fig.sep'] # a vector
    @fig__process = options['fig.process'] 
    @fig__showtext = options['fig.showtext'] 
    @external = options['external'] 
    @sanitize = options['sanitize'] 

    # verifies if figures should be kept
    fig_keep

    # if figures are to be kept, take or guess the file extension
    file_ext
    
    # make final filename
    @filename = "#{@fig__path}#{@label}.#{@fig__ext}"
    @options["filename"] = "."

    # create temporary file for storing plots
    # TODO: should remove this directory afterwards
    @tmp_fig = (R.tempfile().unboxed_get(0))
    
  end

  #--------------------------------------------------------------------------------------
  # @param dev_type [String] name of the device type to open
  # @param filename [String] filename to store the image.  By default nil for the awt
  #    device
  # @param args [Array] other parameters to be passed to device. Right now, there are
  #   no other parameters that should be passed to the available devices.  Might be
  #   needed when more devices are available
  # @param width [Numeric] width of the figure, by default 480
  # @param height [Numeric] hegiht of the figure, by default 480
  # @param units [String] string with units definition, by default 'px'.  Could be
  #   'in', 'cm'
  # @param res [Numeric] resolution in dpi, if not provided set to 72
  # @param pointsize [Numeric]
  # @param bg [String]
  #--------------------------------------------------------------------------------------

  def self.device(dev_type, filename = nil, *args, width: 480, height: 480,
                  units: "px", res: 72, pointsize: 12, bg: "white")

    case dev_type
        
    when "awt"
    when "svg"
      R.svg(filename)
    when "png"
      R.png(filename, width, height, units, pointsize, bg, res, *args)
    when "pdf"
      width_in = width
      height_in = height
      units_s = units.to_s
      if units_s == "px"
        width_in = width.to_f / res.to_f
        height_in = height.to_f / res.to_f
      elsif units_s == "cm"
        width_in = width.to_f / 2.54
        height_in = height.to_f / 2.54
      end
      R.pdf(filename, width_in, height_in, *args)
    when "jpg", "jpeg"
      R.jpeg(filename, width, height, units, pointsize, bg, res, *args)
    when "bmp" 
      R.bmp(filename, width, height, units, pointsize, bg, res, *args)
    else
      raise "Invalid device type #{device}"
    end
    
  end

  #--------------------------------------------------------------------------------------
  # A figure is renderable only if the artifact exists and is valid for its device.
  # For PDFs, enforce at least one page so LaTeX includegraphics won't fail.
  #--------------------------------------------------------------------------------------

  def figure_artifact_ready?(path)
    return false unless File.exist?(path)
    return false unless File.size(path).to_i > 0

    ext = File.extname(path).downcase
    return true unless ext == ".pdf"

    pdf_data = File.binread(path)
    counts = pdf_data.scan(%r{/Count\s+(\d+)}).flatten.map(&:to_i)
    !counts.empty? && counts.max > 0
  rescue StandardError
    false
  end

  #--------------------------------------------------------------------------------------
  # Captures a plot by calling evaluate::plot_snapshot, which has the latest plotted
  # graphics.  
  #--------------------------------------------------------------------------------------
  
  def capture_plot

    # gets a plot snapshot (base R recordPlot via evaluate_plot_snapshot)
    plot = R.evaluate_plot_snapshot

    if (!(plot.is__null.unboxed_get(0)))
      # create directory for the graphics files if does not already exists
      unless File.directory?(@fig__path)
        FileUtils.mkdir_p(@fig__path)
      end

      # use absolute path so the file is created where Ruby expects and include_graphics can find it
      filename_abs = File.expand_path(@filename)
      # Save in one R call (open device, replayPlot, dev.off) so the file is actually written
      w = (@fig__width >> 0) rescue 480
      h = (@fig__height >> 0) rescue 480
      res = (@dpi >> 0) rescue 72
      dev_str = @dev.respond_to?(:>>) ? (@dev >> 0) : @dev.to_s
      dev_str = dev_str.to_s.split.first if dev_str.respond_to?(:to_s)
      units_str = (units.respond_to?(:>>) ? (units >> 0) : units).to_s rescue "in"
      R.save_recorded_plot(filename_abs, plot, w, h, dev_str, res, units_str)
      return plot
    end

    # Fallback when recordPlot() returns NULL on non-screen devices:
    # copy from the active device to the target figure file.
    unless File.directory?(@fig__path)
      FileUtils.mkdir_p(@fig__path)
    end
    filename_abs = File.expand_path(@filename)
    w = (@fig__width >> 0) rescue 480
    h = (@fig__height >> 0) rescue 480
    res = (@dpi >> 0) rescue 72
    dev_str = @dev.respond_to?(:>>) ? (@dev >> 0).to_s : @dev.to_s
    dev_str = dev_str.gsub('"', '').strip

    case
    when dev_str.include?('png')
      R::Support.eval("grDevices::dev.copy(grDevices::png, filename='#{filename_abs.gsub("'", "\\\\'")}', width=#{w}, height=#{h}, units='in', res=#{res}); grDevices::dev.off()")
      return true
    when dev_str.include?('svg')
      R::Support.eval("grDevices::dev.copy(grDevices::svg, filename='#{filename_abs.gsub("'", "\\\\'")}', width=#{w}, height=#{h}); grDevices::dev.off()")
      return true
    when dev_str.include?('pdf')
      R::Support.eval("grDevices::dev.copy(grDevices::pdf, file='#{filename_abs.gsub("'", "\\\\'")}', width=#{w}, height=#{h}); grDevices::dev.off()")
      return true
    end

    false

  end
  
  #--------------------------------------------------------------------------------------
  # Adds the new knitr engine to the list of engines
  # @param spec [Hash] hash with only one pair containing the machine key and the engine
  #    function
  #--------------------------------------------------------------------------------------
  
  def add(spec)
    # Use [[ so R returns the engine function; single bracket [ returns a list, not callable
    R.knitr___knit_engines[["set"]].call(spec)
  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def add_hook(spec)

  end
  
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------
  
  private

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def initialize

    @chunk_index = 0

    # Knitr invokes this proc with top-level self (main). Engine state (@options, @filename,
    # capture_plot, process_options) must run on this KnitrEngine singleton (RubyEngine.instance).
    _gknit_self = self

  #--------------------------------------------------------------------------------------
  # Basic engine for processing a chunk
  #--------------------------------------------------------------------------------------

    @base_engine = Proc.new do |options|
      _gknit_self.instance_eval do
      # grDevices::dev.cur() as an R handle (g2_v*) can be reassigned across NewBridge
      # callbacks; dev.off(that_handle) then sees wrong/empty `which`. Unbox immediately.
      dv_n = nil
      begin

        out = R.list

        # process the chunk options.
        process_options(options)
        @chunk_index += 1
        $stderr.puts "[gknit] Processing chunk #{@chunk_index}: #{@label}"
        
        # Open chunk device directly on the final figure target path so inclusion does not
        # depend on later snapshot copying behavior.
        FileUtils.mkdir_p(@fig__path) unless File.directory?(@fig__path)
        chunk_fig_target = File.expand_path(@filename)
        KnitrEngine.device(@dev.unboxed_get(0), chunk_fig_target)
        
        v = (R.dev__cur >> nil) rescue nil
        if v
          x = v.is_a?(Array) ? v.first : v
          dv_n = x.to_i if x.is_a?(Numeric)
        end

        # executes the code chunk with the given options
        # the returned value is a list properly formatted to be given to engine_output
        # exec_ruby catches StandardError, so no execution errors on the block will
        # reach here, they are formatted in the return list to be printed
        res = GalaazUtil.exec_ruby(@options)
        
        include_chunk = !!@include

        # function engine_output will format whatever is in out inside a white box
        # (exec_ruby now uses simpleMessage/simpleWarning so conditionMessage() works in engine_output)
        out = @echo ? R.engine_output(@options, out: res) : res
        
        # ouputs the data in RubyChunk '@outputs' variable. Everything that should
        # be processed by 'pandoc' and not appear in the output block from
        # engine_output, should be outputed with the 'outputs' function and will be
        # stored in the @outputs variable
        # out = R.c(out, RubyChunk.get_outputs)
        out = R.c(out, RChunk.out_list)
        RChunk.reset_outputs
        
        # Finalize the chunk device before testing/including artifact; PDF files are not
        # valid for includegraphics until dev.off() closes the page stream.
        if dv_n.is_a?(Integer) && dv_n > 1
          R.dev__off(dv_n)
          dv_n = nil
        end

        # Include only real, renderable figure artifacts for this chunk.
        if include_chunk
          fig_path = File.expand_path(@filename)
          if figure_artifact_ready?(fig_path)
            fig_rel = Pathname.new(fig_path).relative_path_from(Pathname.new(Dir.pwd)).to_s rescue fig_path
            fig_md = "![](" + fig_rel + ")"
            out = R.c(out, fig_md)
          end
        end

        # knitr semantics: include=FALSE still evaluates code/side effects, but emits nothing.
        out = R.list unless include_chunk

        out
        
      rescue StandardError, RuntimeError => e
        # Format error with newlines so R/knitr displays it on multiple lines (not semicolon-joined).
        formatted = e.message.to_s
        formatted += "\n\n--- Ruby backtrace ---\n" + e.backtrace.join("\n") if e.backtrace && !e.backtrace.empty?
        R.list(R.simpleMessage(formatted))
      ensure
        # Close the device we opened (which > 1; 1 is the null device and must not be passed to dev.off).
        if dv_n.is_a?(Integer) && dv_n > 1
          R.dev__off(dv_n)
        end
      end
      end
    end

    super
    
  end
  
end
