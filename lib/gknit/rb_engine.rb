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

class RbEngine < KnitrEngine
  include Singleton

  attr_reader :engine

  #--------------------------------------------------------------------------------------
  # Ruby engine for processing Ruby chunks
  #--------------------------------------------------------------------------------------

  def initialize
    
    @engine = Proc.new do |options|

      # puts options
      
      begin

        # the 'rb' engine has the code to be executed in the options.label
        # argument
        puts options[['code']]
        puts options[['label']]
        
        options[['code']] = options[['label']]
        GalaazUtil.exec_ruby(options)

      ensure
        # closes the current device
        # R.dev__off(dv)
      end
      
    end

    # Add the rb engine function for processing the rb block
    add(rb: @engine)

  end
  
end

rb_engine = RbEngine.instance

