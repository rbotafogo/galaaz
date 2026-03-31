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

class IncludeEngine < KnitrEngine
  include Singleton

  attr_reader :engine

  #--------------------------------------------------------------------------------------
  # Ruby engine for processing 'include' chunks
  #--------------------------------------------------------------------------------------

  def initialize

    # call super to make @base_engine available
    super
         
    @engine = Proc.new do |options|
      # Ensure include chunks always load file content into options['code'].
      # This keeps include behavior working even if R-side wrappers are replaced.
      begin
        label = options['label'].unboxed_get(0).to_s
        relative_opt = options['relative']
        relative =
          if relative_opt.respond_to?(:unboxed_get)
            !!relative_opt.unboxed_get(0)
          else
            false
          end
        options.code = GalaazUtil.inline_file(label, relative)
      rescue StandardError => e
        options.code = "# Include failed: #{e.message}"
      end
      @base_engine.call(options)
    end
    
    # Add the include engine function for processing the rb block
    add(include: @engine)
    
  end
  
end

include_engine = IncludeEngine.instance

