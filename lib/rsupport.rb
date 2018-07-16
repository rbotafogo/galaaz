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
    
    #----------------------------------------------------------------------------------------
    #
    #----------------------------------------------------------------------------------------
    
    def self.eval(string)
      Polyglot.eval("R", string)
    end

    #----------------------------------------------------------------------------------------
    #
    #----------------------------------------------------------------------------------------
    
    def self.parse_arg(arg)
      
      # if this is an R object, leave it alone
      if (Truffle::Interop.foreign?(arg) == true)
        return arg
      elsif (arg == :all)
        R.empty_symbol
      elsif (arg.is_a? Integer)
        arg.to_f
      elsif (arg.is_a? R::Object)
        return arg.r_interop
      elsif (arg.is_a? NegRange)
        final_value = (arg.exclude_end?)? (arg.last - 1) : arg.last
        return R::Support.eval("seq").call(arg.first, final_value)
      elsif (arg.is_a? Range)
        final_value = (arg.exclude_end?)? (arg.last - 1) : arg.last
        return R::Support.eval("seq").call(arg.first, final_value)
      elsif (arg.is_a? Hash)
        raise "Ilegal parameter #{arg}"
      else
        return arg
      end
      
    end
    
  end

end
