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
R.install_and_loads('ISLR', 'MASS')

describe R::Language do

  #========================================================================================
  context "When working with Formulas" do
    
    it "should create formulas with the '=~' operator" do
      formula = (:cyl.til :exp)
      expect(formula.to_s).to eq "cyl ~ exp"
      rform = R.identity(formula)
      expect(rform.typeof).to eq 'language'
      expect(rform.rclass).to eq 'formula'
    end

    it "should create a formula with '.' by using the ':all' keyword in the rhs" do
      # this formula is interpreted as 'supp ~ .' In this statement formula
      # is an R::Expression which has infix and prefix notation
      formula = :supp.til :__
      expect(formula.to_s).to eq "supp ~ ."
      expect(formula.rclass).to eq "formula"
      expect(formula.typeof).to eq "language"
    end
    
    it "should create a formula with '.' by using the ':all' keyword in the lhs" do
      # this formula is interpreted as '. ~ supp'
      formula = :__.til :supp
      expect(formula.to_s).to eq ". ~ supp"
      expect(formula.rclass).to eq "formula"
      expect(formula.typeof).to eq "language"
    end

  end

  #========================================================================================
  context "When modeling with formulas" do

    before(:each) do
      @boston_lm = R.lm((:medv.til :lstat), data: :Boston)
    end

    it "should obtain data from the model" do
      expect(@boston_lm.coefficients[[1]].all__equal(34.5538408)).to eq true
      expect(@boston_lm.coefficients[[2]].all__equal(-0.950049353)).to eq true

      expect(@boston_lm.names[[1]]).to eq "coefficients"
      expect(@boston_lm.names[[2]]).to eq "residuals"
      expect(@boston_lm.names[[12]]).to eq "model"
    end

    it "should do predictions (confidence) based on the model" do
      # predict the confidence interval
      conf = R.predict(@boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))),
                       interval: "confidence")
      expect(conf[1, :all][['fit']].all__equal(29.8035941)).to eq true
      expect(conf[2, :all][['lwr']].all__equal(24.4741320)).to eq true
      expect(conf[3, :all][['upr']].all__equal(20.8746129)).to eq true
    end

    it "should do prediction (prediction) based on the model" do
      pred = R.predict(@boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))),
                       interval: "prediction")
      expect(pred[1, :all][['fit']].all__equal(29.8035941)).to eq true
      expect(pred[2, :all][['lwr']].all__equal(12.82762634)).to eq true
      expect(pred[3, :all][['upr']].all__equal(32.5284590)).to eq true
    end

    it "should do multiple linear regression" do
      # Multiple linear regression from ISLR book.  Chapter 3 Lab, pg 113
      lm_fit = R.lm((:medv.til :lstat + :age), data: :Boston)
      puts lm_fit.summary

      lm_fit5 = R.lm((:medv.til E.poly(:lstat, 5)), data: :Boston)
      puts lm_fit5
    end

  end

end
