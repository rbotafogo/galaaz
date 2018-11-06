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

# Ruby engine for processing Ruby chunks
eng_ruby = Proc.new do |options|

  begin
    # read the chunk code
    code = R.paste(options.code, collapse: "\n") << 0
    
    # process the chunk options
    KnitrEngine.process_options(options)

    tmp_fig = R.tempfile()
     
    # opens a device for the current chunk for plot recording. Knitr provides
    # method chunck_device for that, but it is a non-exported method.  Galaaz
    # does not yet provide a way to accessing non-exported methods, so, the ck_dv
    # local method was developed that just calls chunk_device.
    if (R._ck_dv(options.fig__width[1], options.fig__height[1], options.dev,
                 options.dev__args, options.dpi, options, tmp_fig, record: true) << 0)

      # chunk requires library 'showtext'.  Install and loads if not present
      # FIXME: library showtext is giving error when trying to execute showtext beginning
      if (!options[['fig.showtext']].is__null << 0) &&
         options[['fig.showtext']] << 0
        R.install_and_loads('showtext')
        R.showtext
      end
      
      dv = R.dev__cur
    end
    
    # executes the code
    res = GalaazUtil.exec_ruby(code)
    
    # formats and outputs the code and results
    R.engine_output(options, options.code, res)

  ensure
    R.dev__off(dv)
    # tmp_fig.unlink
    # if (keep.pars) opts_knit$set(global.pars = par(no.readonly = TRUE))
  end
  
end

ruby_engine = KnitrEngine.new
ruby_engine.add(ruby: eng_ruby)
