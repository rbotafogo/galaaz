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
        function(obj, ...) {
          sink(tt <- textConnection("results","w"), split=FALSE, type = c("output", "message"));
          print(obj, ...);
          sink();
          close(tt);
          results
        }
      R
    end

    def self.start_capture
      Polyglot.eval("R", <<-R)
        function(cap_variable) {
          sink(con <- textConnection(cap_variable,"w"), split=FALSE, type = c("output"));
          con
        }
      R
    end

    def self.stop_capture
      Polyglot.eval("R", <<-R)
        function(con) {
          sink();
          close(con);
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
    # R function that returns another R function that calls back a Ruby Method or Proc
    # Some R functions that receive a function as argument will test to see if their
    # parameters is a function or a symbol, so the Ruby method needs to be wrapped inside
    # an R function in order for it to pass this test.
    #--------------------------------------------------------------------------------------

    def self.ruby_callback_method
      Polyglot.eval("R", <<-R)
        function(rb_method) {
          function(...) {
          rb_method(...)
          }
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

  end
  
end
