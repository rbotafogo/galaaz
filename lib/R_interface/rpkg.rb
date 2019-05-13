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
  
  #----------------------------------------------------------------------------------------
  # 
  #----------------------------------------------------------------------------------------

  class Package

    @@packages = {}
    
    def self.[](package_name)
      return @@packages[package_name] if @@packages.has_key?(package_name)
      @@packages[package_name] = new(package_name)
    end

    def initialize(package_name)
      @package_name = package_name
    end
    
    def method_missing(symbol, *args)
      symbol = R::Support.convert_symbol2r(symbol)
      R::Support.exec_function_name("#{@package_name}::#{symbol}", *args)
    end

    private_class_method :new
    
  end
  
  #----------------------------------------------------------------------------------------
  # 
  #----------------------------------------------------------------------------------------

  def self.const_missing(name)
    R::Package[name.to_s.downcase]
  end

end
  
