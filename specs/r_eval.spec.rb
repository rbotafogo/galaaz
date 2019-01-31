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

require 'galaaz'

describe R do

  context "Accessing R through R::Support.eval" do

    before(:each) do
      R::Support.eval(<<-R)
        # x is a "double" vector
        x <- c(1, 2, 3)
        hyp <- function(x, y) { sqrt(x^2 + y^2) };
      R
    end

    it "Integer values in R are automatically unboxed as float" do
      var = R::Support.eval("5L")
      # although var is an Interop, it is automatically unboxed, when it is a vector of length
      # one, and can thus be compared with a number.
      expect(5).to eq var
      expect(5.0).to eq var
    end

    it "Interop pointers can be operated through eval" do
      var = R::Support.eval("5L")
      # calling method 'class' on var returns a vector of size one with a string that
      # contains the class of the object
      expect("integer").to eq R::Support.eval("class").call(var).to_s
    end
    
    it "A number evaluated in R is automatically unboxed as float in Ruby" do
      var = R::Support.eval("4")
      expect(4.0).to eq var
      expect("numeric").to eq R::Support.eval("class").call(var).to_s
    end

    it "R vectors can be indexed by the indexing method of the host language" do
      var = R::Support.eval("'Hello'")
      expect(var[0]).to eq "Hello"
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

  end

  context "Basic access to R without R::Support" do
    
    it "should retrieve named R objects to Ruby variables by using '~' " do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = ~:x

      expect(x.is_a? R::Vector).to eq true
      expect(x.length).to eq 3
      # it is not a foreign object. It's an R::Vectors
      expect(Truffle::Interop.foreign?(x)).to be false
      # Values are indexed starting with 1, the same as R notation
      expect(x[1]).to eq 1.0
    end

    it "should return a String Vector" do
      # Interop will take a one dimensional array and return the value of the first
      # element.  This might change on a future release. At the present moment, var
      # becomes a character array with 5 elements
      var = R.c("Hello")
      
      expect(var.length).to eq 1
      expect(var.typeof).to eq "character"
      expect(var.is_a? R::Vector).to eq true
      expect(var[1]).to eq "Hello"
    end
    
    it "shoud access named objects in R" do
      # to create a double vector through the Ruby interface, we need that at least
      # one element of the vector is a 'float'
      double = R.c(1.0, 2, 3)
      expect((~:x).identical double).to eq true
      expect(R.hyp(3, 4).all__equal(5)).to eq true
      # @TODO: this should work but raises the following error:
      # TypeError:
      #  Truffle doesn't have a case for the org.truffleruby.interop.InteropNodesFactory$HasSizeNodeFactory$HasSizeNodeGen node with values of type  java.lang.Double=5.0
      # I think this is a bug with TruffleRuby that hopefully will be fixed in RC12
      # If not fixed in RC12 open issue
      # expect(R.hyp(3, 4)).to eq 5
    end

    it "should box R functions in R::Closure Ruby class" do
      # hyp is an R function and works like a named function in Ruby
      hyp = ~:hyp
      
      # calling a named function or block is done by use of the 'call' method
      expect(hyp.call(3, 4)).to eq 5.0
      expect(hyp.typeof).to eq "closure"
      expect(hyp.is_a? R::Closure).to eq true
    end
    
    it "should print values the same way as R" do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = ~:x
      
      # Converting to string (to_s) will print as an R vector would
      expect(x[1].to_s).to eq ("[1] 1")
      expect(x.to_s).to eq ("[1] 1 2 3")
    end

    it "should allow logical comparison using R::Objects" do
      # retrieve x and hyp from R and attribute it to local Ruby variables
      x = ~:x

      expect(x[1].all__equal(1)).to eq true
      expect(x[2].identical(1)).to eq false
      expect((x << 0) == 1).to eq true
    end
    
    it "should have NA" do
      expect(R.is__na R::NA).to eq true
    end
    
  end

end
