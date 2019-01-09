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
  context "Using Ruby Procs as parameters to R functions and expressions" do

    before(:each) do
      @x = @y = R.seq(-~:pi, ~:pi, length: 10)
    end
    
    it "should accept a Proc as parameter" do
      # call R outer function passing in a Proc
      # note that x and y are Ruby objects that were received from an
      # R function, so they are R::Vectors or another type of R::Object. We
      # can operate on them with R functions: for instance, R.cos(y)
      f = R.outer(@x, @y,
                  lambda { |x, y|
                    R.cos(y) / (x**2 + 1)})
      expect(f[1, 1].all__equal -0.091999668).to eq true
      expect(f[7, 6].all__equal 0.448193475).to eq true
    end

    it "should accept a Method as parameter" do

      module Calculation
        # note that x and y are Ruby objects that were received from an
        # R function, so they are R::Vectors or another type of R::Object.  We
        # can operate on them with R functions: for instance, R.cos(y)
        def self.func(x, y)
          R.cos(y) / (x**2 + 1)
        end
      end

      f = R.outer(@x, @y, Calculation.method(:func)) 
      expect(f[1, 1].all__equal -0.091999668).to eq true
      expect(f[7, 6].all__equal 0.448193475).to eq true
    end
    
    it "should accept Procs in Expressions" do
      
      df = R.data__frame(x: @x, y: @y)
      # create a quoted function f that takes 3 parameters :x, :y and a Proc
      # we want to evaluate f in the scope of the dataframe 'df'
      f = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
      
      # now lets evaluate f in the scope of df, where :x and :y are defined
      res = f.eval(df)
      expect(res[1, 1].all__equal -0.091999668).to eq true
      expect(res[10, 9].all__equal -0.0704758347).to eq true
    end

    it "Should be able to 'eval' a Proc in expression" do
      
      df = R.data__frame(x: R.c(1, 2, 3), y: R.c(4, 5, 6))
      f = E.outer(:x, :y, Proc.new { |x, y| x + y })
      
      res = f.eval(df)
      expect(res[1, :all] == R.c(5, 6, 7)).to eq true
      expect(res[3, :all] == R.c(7, 8, 9)).to eq true

    end
      
  end
  
end
