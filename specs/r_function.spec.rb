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

  #----------------------------------------------------------------------------------------
  context "When calling R functions" do

    # Let's call a function passing named parameters
    it "should pass named parameters" do
      # Named parameters are in Ruby are converted to named parameters in R
      m = R.matrix(R.seq(1, 10), nrow: 2,
                   dimnames: R.list(R.c("1", "2"),
                                    R.c("a", "b", "c", "d", "e")))
      expect(m.dimnames[[1]].identical(R.c("1", "2"))).to eq true
      expect(m.dimnames[[2]].identical(R.c("a", "b", "c", "d", "e"))).to eq true
    end

  end

  #----------------------------------------------------------------------------------------
  context "Using Ruby Procs as parameters to R functions" do

    it "should accept a Proc as parameter" do
      x = y = R.seq(-R.pi, R.pi, length: 7)
      # call R outer function passing in a Proc
      # note that x and y are Ruby objects that were received from an
      # R function, so they are R::Vectors or another type of R::Object. We
      # can operate on them with R functions: for instance, R.cos(y)
      f = R.outer(x, y,
                  lambda { |x, y|
                    R.cos(y) / (x**2 + 1)})
      expect(f[1, 1] == -0.09199967).to eq true
      expect(f[7, 6] == -0.04599983).to eq true
    end

    it "should accept a Method as parameter" do
      x = y = R.seq(-R.pi, R.pi, length: 7)

      module Calculation
        # note that x and y are Ruby objects that were received from an
        # R function, so they are R::Vectors or another type of R::Object.  We
        # can operate on them with R functions: for instance, R.cos(y)
        def self.func(x, y)
          R.cos(y) / (x**2 + 1)
        end
      end

      f = R.outer(x, y, Calculation.method(:func))
      expect(f[1, 1] == -0.09199967).to eq true
      expect(f[7, 6] == -0.04599983).to eq true
      
    end
    
  end
  
  
end
