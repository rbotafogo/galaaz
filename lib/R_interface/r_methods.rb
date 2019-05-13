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

    def self.capture2
      Polyglot.eval("R", <<-R)
        function(obj, ...) {
          tryCatch({
            sink(tt <- textConnection("results","w"), split=FALSE, type = c("output", "message"));
            print(obj, ...);
            sink();
            results
          }, finally = {
            close(tt);
          })
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
    #
    #--------------------------------------------------------------------------------------

    def self.dbk_index
      Polyglot.eval("R", <<-R)
        function(obj, ...) {
          obj[[...]]
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
    #
    #--------------------------------------------------------------------------------------
    
    def self.enquo
      Polyglot.eval("R", <<-R)
        function(x, ...) {
          enquo(x)          
        } 
      R
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def self.range
      Polyglot.eval("R", <<-R)
        function(x, y, neg = FALSE) {
          e1 = enexpr(x)
          e2 = enexpr(y)
          if (neg) {
            expr(-(!!e1:!!e2))
          } else {
            expr(!!e1:!!e2)
          }
        }
      R
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    def self.create_bin_expr(operator)
      is_formula = (operator == "`~`")? 'TRUE' : 'FALSE'
      Polyglot.eval("R", <<-R)
        function(op1, op2) {
          o1 = enexpr(op1)
          o2 = enexpr(op2)
          if (typeof(o1) == 'symbol' && o1 == expr(`__`)) {
            o1 = expr(.)
          }
          if (typeof(o2) == 'symbol' && o2 == expr(`__`)) {
            o2 = expr(.)
          }
          exp = expr(#{operator}(!!o1, !!o2))
          if (#{is_formula}) {
            as.formula(exp)
          } else {
            exp
          }
        }
        R
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    Polyglot.eval("R", <<-R)
      plot = function(...) {
        print("Function 'plot' is not implemented in fastR.  Please, use ggplot instead")
      }
    R

  end
  
end
