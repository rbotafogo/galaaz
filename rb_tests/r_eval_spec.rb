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

require '../config'
require 'cantata'

describe R do
  
  context "Accessing R through eval" do

    it "shoud create named objects in R" do
      # using Ruby heredoc to write R code
      R.eval(<<-R)
      x <- c(1, 2, 3);
      hyp <- function(x, y) { sqrt(x^2 + y^2) };
      R
    end
    
    it "should use named objects in R" do
      R.eval(<<-R)
      print(x);
      print(hyp(3, 4));
      R
    end

    it "should retrieve and used named R objects in Ruby" do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = R.eval("x")
      # hyp is an R function and works like a named function in Ruby
      hyp = R.eval("hyp")

      # is is a foreign object
      expect(Truffle::Interop.foreign?(x)).to be true
      expect(x[0]).to eq 1.0

      # calling a named function or block is done by use of the 'call' method
      expect(hyp.call(3, 4)).to eq 5.0

    end
  end

end
