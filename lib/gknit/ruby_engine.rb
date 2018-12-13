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

class RubyEngine < KnitrEngine
  include Singleton

  attr_reader :eng_ruby

  #--------------------------------------------------------------------------------------
  # Ruby engine for processing Ruby chunks
  #--------------------------------------------------------------------------------------
  
  def initialize

    @eng_ruby = Proc.new do |options|
      
      begin
        # process the chunk options.
        # KnitrEngine.process_options(options)
        process_options(options)
        
        # verifies if figures should be kept
        fig_keep
        
        # if figures are to be kept, take or guess the file extension
        file_ext
        
        # make final filename
        @filename = "#{@fig__path}#{@label}.#{@fig__ext}"
        @options["filename"] = "."

        # create temporary file for storing the plots
        # TODO: should remove this directory afterwards
        tmp_fig = (R.tempfile() << 0)

        # opens a device for the current chunk for plot recording
        KnitrEngine.device(options.dev << 0, tmp_fig)

        # chunk requires library 'showtext'.  Install and loads if not present
        # FIXME: library showtext is giving error when trying to execute showtext beginning
        if (!options[['fig.showtext']].is__null << 0) &&
           options[['fig.showtext']] << 0
          R.install_and_loads('showtext')
          R.showtext
        end

        dv = R.dev__cur

        # executes the code
        res = GalaazUtil.exec_ruby(options)

        # @TODO: variable 'res' has the code, output, warning and messages... need to
        # deal with all of them to output only what is required and respect the
        # flags...
        # formats and outputs the code and results
        R.engine_output(options, out: res) if @echo

        if (!((@options[['filename']] == '.') << 0))
          # include chunk graphics
          R.knitr_wrap(R.knit_print(R.include_graphics(@options.filename << 0)), @options)
        end
      
      ensure
        R.dev__off(dv)
      end

    end # end proc

    add(ruby: @eng_ruby)
    
  end

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  def capture_plot

    # gets a plot snapshot.  Uses function plot_snapshot from package 'evaluate'
    plot = R.evaluate_plot_snapshot

    if (!(plot.is__null << 0))

      # create directory for the graphics files if does not already exists
      unless File.directory?(@fig__path)
        FileUtils.mkdir_p(@fig__path)
      end

      @options["filename"] = @filename

      @options.dev.each do |dev_type|
        KnitrEngine.device(dev_type << 0, @filename,
                           width: @options.fig__width << 0,
                           height: @options.fig__height << 0, units: units)
        R.print(plot)
        R.dev__off
      end

    end

  end

end

ruby_engine = RubyEngine.instance

