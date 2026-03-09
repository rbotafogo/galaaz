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

module R

  module Support

    # Galaaz 2.0: In the Shadow Bridge, these methods return 
    # the name of the R function as a string handle.

    def self.capture
      "capture" # Requires capture to be defined in R
    end

    def self.capture2
      "capture2"
    end
    
    def self.start_capture
      "start_capture"
    end

    def self.stop_capture
      "stop_capture"
    end

    def self.dbk_index
      "`[[`"
    end
    
    def self.md_index
      "`[`"
    end

    def self.ruby_callback_method
      "ruby_callback_method"
    end
    
    def self.enquo
      "enquo"
    end

    def self.range
      "range_helper"
    end

    def self.create_bin_expr(operator)
      "function(op1, op2) { #{operator}(op1, op2) }"
    end

  end
  
end
