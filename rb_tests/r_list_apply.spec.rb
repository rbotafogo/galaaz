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

describe R::List do

  context "The apply family of functions with lists" do

    before(:all) do
      @x = R.list(a: (1..10), beta: R.exp(-3..3), logic: R.c(true, false, false, true))
      R.library("stats")
      # Make @q the function R quantile
      @q = R.quantile
    end
    
    it "should work with lapply and mean" do
      # lapply applies a function to each element of a list or vector, returning a list.
      # compute the list mean for each list element
      mean = R.lapply(@x, "mean")
      expect(mean.a).to eq 5.5
      
      # R.all__equal(x,y) is a utility to compare R objects x and y testing
      # “near equality”. If they are different, comparison is still made to some extent,
      # and a report of the differences is returned. Don't use R.all__equal directly
      # in if expressions—either use isTRUE(all.equal(....)) or identical if appropriate.
      # We cannot do mean.beta.all__equal in this case, since mean.beta is a Ruby float
      # and method all__equal is not defined on floats.
      expect(R.all__equal(mean.beta,
                          4.5351252347,
                          tolerance: R.__Machine.double__eps ** 0.5)).to eq true

      expect(mean.logic).to eq 0.5
    end
    
    it "should allow using lapply with quantile" do
      # lapply applies a function to each element of a list or vector, returning a list.
      # median and quartiles for each list element
      quant = R.lapply(@x, @q)
      expect(quant.a[1]).to eq 1
      expect(quant.a["50,00000%"]).to eq 5.50
      expect(R.all__equal(quant.beta["100,0000%"],
                          20.08553692,
                          tolerance: R.__Machine.double__eps ** 0.5)).to eq true
      expect(quant.logic[2]).to eq 0.0
    end
    
    it "should allow using sapply and quantile" do
      quant = R.sapply(@x, @q)
      quant.pp
    end

    it "should allow using method lapply with quantile" do
      x = R.lapply(@x, @q, R.c(0.25, 0.50, 0.75))
      x.pp
    end
    
    it "should sapply to a sequence" do
      # sapply isn’t content to always return a list: it attempts to simplify
      # the results into a non-list vector if possible.
      R.library("stats")
      
      i39 = R.sapply((3..9), "seq")
      i39.pp
      sap = R.sapply(i39, R.fivenum)
      sap.pp
    end
  
  end
  
end
