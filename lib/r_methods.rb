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
    
    #--------------------------------------------------------------------------------------
    # Captures the R output to a variable and returns it. 
    #--------------------------------------------------------------------------------------
    
    def self.capture
      
      Polyglot.eval("R", <<-R)
        function(...) {
          sink(tt <- textConnection("results","w"),split=FALSE);
          print(...);
          sink();
          close(tt);
          results
        }
      R
      
    end 
    
    #--------------------------------------------------------------------------------------
    # multi-dimensional indexing
    #--------------------------------------------------------------------------------------
    
    def self.md_index
      Polyglot.eval("R", <<-R)
        function(mdobject, ...) { 
          mdobject[...];
        }
      R
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
    
    def self.all_equal
      Polyglot.eval("R", "function(...) all.equal(...)")
    end

    def self.as_data_frame
      Polyglot.eval("R", "function(x) as.data.frame(x)")
    end

    def self.print
      Polyglot.eval("R", "function(x) print(x)")    
    end
    
    def self.subset
      Polyglot.eval("R", "function(...) subset(...)")    
    end

    def self.levels
      Polyglot.eval("R", "function(x) levels(x)")    
    end
    
  end
  
end
