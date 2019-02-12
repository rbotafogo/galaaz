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
        process_options(options)
        
        # opens a device for the current chunk for plot recording
        KnitrEngine.device(options.dev << 0, @tmp_fig)

        # dv gets the current device
        dv = R.dev__cur

        # executes the code chunk with the given options
        # the returned value is a list properly formatted to be given to engine_output
        # exec_ruby catches StandardError, so no execution errors on the block will
        # reach here, they are formatted in the return list to be printed
        res = GalaazUtil.exec_ruby(options)
        
        # function engine_output will format whatever is in out inside a white box
        out = R.engine_output(options, out: res) if @echo

        # 
        out = R.c(out, RubyChunk.get_outputs)
        
        # @TODO: allow capturing many plots in the block.  For now, only the last
        # plot will be captured.  Not a very serious problem for now.
        # Captures the last plot in the Ruby block. 
        if (capture_plot)
          plot = R.knitr_wrap(R.knit_print(R.include_graphics(@filename)), @options)

          # add to the output the result of plot.  Whatever is included after the
          # engine_output output will appear 'as.is' in the report.  The 'plot'
          # variable is a command that in rmarkdown includes the image in the
          # report
          out = R.c(out, plot)
        end

        out

      ensure
        # closes the current device
        # R.dev__off(dv)
      end
      
    end

    # Add the ruby engine function for processing the ruby block
    add(ruby: @eng_ruby)

  end
  
end

ruby_engine = RubyEngine.instance

