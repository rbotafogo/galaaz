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

R.install_and_loads('knitr', 'rmarkdown')

# dir = File.dirname(File.expand_path('.', __FILE__))
# src = "#{dir}/R/eng_ruby.R"

class KnitrEngine

  attr_reader :options
  attr_reader :keep

  #--------------------------------------------------------------------------------------
  # opens a device for plot recording.  Method chunk_device in knitr is not exported,
  # so it cannot yet be accessed by Galaaz.  Need to develop a local function that calls
  # the non-exported function.
  #--------------------------------------------------------------------------------------

  R::Support.eval(<<-R)
    _ck_dv = function(width, height, record = TRUE, dev, dev.args, dpi, options, 
                      tmp = tempfile()) {
        knitr:::chunk_device(width, height, record, dev, dev.args, dpi, options, tmp)
      }
    R

  #--------------------------------------------------------------------------------------
  # The showtext package, is able to support more font formats and more graphics
  # devices, and avoids using external software such as Ghostscript. showtext makes it
  # even easier to use various types of fonts (TrueType, OpenType, Type 1, web fonts,
  # etc.) in R graphs.
  #--------------------------------------------------------------------------------------

  R::Support.eval(<<-R)
    showtext = function() {
      showtext::showtext_begin()
    }
  R
    
  #--------------------------------------------------------------------------------------
  # Process the fig.keep chunk option
  # @param keep [String/Numeric] a string or a number.  If it is a string then it should
  #   be one of the following: 
  #   * high: only keep high-level plots (merge low-level changes into high-level plots);
  #   * none: discard all plots;
  #   *  all: keep all plots (low-level plot changes may produce new plots)
  #   * first: only keep the first plot
  #   * last: only keep the last plot
  #   if set to a numeric vector: interpret value as index of (low-level) plots to keep
  #   In this case, set variable @keep to "index" and variable @keep_ind as the numeric
  #   index.
  #--------------------------------------------------------------------------------------

  def self.fig_keep
    @keep = @options.fig__keep
    @keep_idx = nil

    if (@keep.is__numeric << 0)
      @keep_idx = @keep
      @keep = "index"
    end

  end

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------

  def self.file_ext
    # guess plot file type if it is NULL
    if (@keep != 'none' && @options.fig__ext.is__null)
      @options.fig__ext = R.dev2ext(@options.dev)
    end
  end
    
  #--------------------------------------------------------------------------------------
  # Process the chunk options
  #--------------------------------------------------------------------------------------
  
  def self.process_options(options)
    @options = options
    
    # verifies if figures should be kept
    fig_keep
    
    # if figures are to be kept, take or guess the file extension
    # file_ext
  end

  #--------------------------------------------------------------------------------------
  # Adds the new knitr engine to the list of engines
  # @param spec [Hash] hash with only one pair containing the machine key and the engine
  #    function
  #--------------------------------------------------------------------------------------
  
  def add(spec)
    (~:knit_engines).set.call(spec)
  end
  
end
