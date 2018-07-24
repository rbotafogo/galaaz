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

    before(:all) do
      R::Support.eval(<<-R)
        # x is a "double" vector
        x <- c(1, 2, 3)
        hyp <- function(x, y) { sqrt(x^2 + y^2) };
      R
    end

    it "should return an Integer Ruby object if the vector is of length one followed by 'L'" do
      # var is an Interop pointer.  In principle, one should not need to use
      # R::Support.eval.  This is used only when one really needs to escape to R
      # directly.
      var = R::Support.eval("5L")
      expect(5).to eq var
      # use method class to get the class of an Interop object
      expect(var.class).to eq Integer
    end

    it "should return a Float Ruby object if the vector is numeric of length one" do
      var = R::Support.eval("4")
      expect(4.0).to eq var
      expect(var.class).to eq Float
    end

    # This has a bug that will be fixed by next version of Truffle
    it "should work with characters" do
      var = R::Support.eval("'Hello'")
      expect { var[0] }.to raise_error { NoMethodError }
      # expect("H").to eq var
    end

    it "should return a string if the vector is a string of length one" do
      # Interop will take a one dimensional array and return the value of the first
      # element.  This might change on a future release. At the present moment, var1
      # becomes a character array with 5 elements
      var1 = R.c("Hello")
      expect(var1.size).to eq 5
      expect(var1[0]).to eq "H"
    end
    
    it "shoud access named objects in R" do
      # to create a double vector through the Ruby interface, we need that at least
      # one element of the vector is a 'float'
      double = R.c(1.0, 2, 3)
      expect(R.x.identical(double)).to eq true
      expect(R.hyp(3, 4)).to eq 5
    end

    it "should retrieve named R objects to Ruby variables using eval. Returned value should be an Interop" do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = R::Support.eval("x")
      # hyp is an R function and works like a named function in Ruby
      hyp = R::Support.eval("hyp")

      # is is a foreign object
      expect(Truffle::Interop.foreign?(x)).to be true
      # we can index the object starting at 0.  This is a property offered by
      # Interop API
      expect(x[0]).to eq 1.0

      # calling a named function or block is done by use of the 'call' method
      expect(hyp.call(3, 4)).to eq 5.0
    end

    it "should retrieve named R objects to Ruby variables by using 'R.'. Returned value should be a Ruby object" do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = R.x
      # hyp is an R function and works like a named function in Ruby
      hyp = R.hyp

      # it is not a foreign object
      expect(Truffle::Interop.foreign?(x)).to be false
      # Values are indexed starting with 1, the same as R notation
      expect(x[1]).to eq 1.0

      # calling a named function or block is done by use of the 'call' method
      expect(hyp.call(3, 4)).to eq 5.0
    end
    
  end
  
end
