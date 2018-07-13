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

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------

  @@empty_symbol = Polyglot.eval("R", <<-R)
    __missing_arg = quote(f(,0));
    __missing_arg[[2]]
  R

  def self.empty_symbol
    @@empty_symbol
  end

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------

  def self.get_attr
    Polyglot.eval("R", "attr")
  end
  
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  @@set_attr = Polyglot.eval("R", <<-R)
    function(object, which, value) {
      attr(object, which) = value;
      object   
    }
    R

  def self.set_attr
    @@set_attr
  end
  
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  # define a function to access the subset '[' method
  @@subset = Polyglot.eval("R", <<-R)
    function(object, index) {
      return(object[index])
    }
  R

  def self.subset
    @@subset
  end
  
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  @@double_subset = Polyglot.eval("R", <<-R)
    function(object, index) {
      return(object[[index]])
    }
  R

  def self.dbk_subset
    @@double_subset
  end
  
  #--------------------------------------------------------------------------------------
  # multi-dimensional indexing
  #--------------------------------------------------------------------------------------

  @@md_index = Polyglot.eval("R", <<-R)
    function(mdobject, ...) { 
      mdobject[...];
    }
  R

  def self.md_index
    @@md_index
  end

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------

  @@md_dbk_index = Polyglot.eval("R", <<-R)
    function(mdobject, ...) {
      mdobject[[...]]
    }
  R

  def self.md_dbk_index
    @@md_dbk_index
  end
  
  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  def self.subset_assign
    Polyglot.eval("R", "`[<-`")
  end

  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  def self.dbk_assign
    Polyglot.eval("R", "`[[<-`")      
  end

  #--------------------------------------------------------------------------------------
  # @bug Needed to create method print because dispatch is not working properly
  #--------------------------------------------------------------------------------------
  
  def self.print
    Polyglot.eval("R", "function(x) print(x)")    
  end
  
  #--------------------------------------------------------------------------------------
  # @bug Needed to create method to_data_frame because dispatch is not working properly
  #--------------------------------------------------------------------------------------

  def self.to_data_frame
    Polyglot.eval("R", "function(x) as.data.frame(x)")
  end

  #--------------------------------------------------------------------------------------
  # @bug Needed to create method row__names because dispatch is not working properly
  #--------------------------------------------------------------------------------------

  def self.set_row_names
    Polyglot.eval("R", "function(object, x) row.names(object) <- x")
  end
  
  def self.get_row_names
    Polyglot.eval("R", "function(x) row.names(x)")
  end
  
end
