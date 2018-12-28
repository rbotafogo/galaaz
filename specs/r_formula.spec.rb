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
    
    it "should create formulas with the '^' operator" do
      formula = (:cyl ^ :exp)
      expect(formula.to_s).to eq "(cyl ~ exp)"
      rform = R.identity(formula)
      expect(rform.typeof).to eq 'language'
      expect(rform.rclass).to eq 'formula'
    end

    it "should create a formula with '.' by using the ':all' keyword in the rhs" do
      # this formula is interpreted as 'supp ~ .' In this statement formula
      # is an R::Expression which has infix and prefix notation
      formula = :supp ^ :all
      expect(formula.to_s).to eq "(supp ~ .)"
      # This is now an R::RExpression
      rform = R.identity(formula) 
      expect(rform.rclass).to eq "formula"
      expect(rform.typeof).to eq "language"
    end
    
    it "should create a formula with '.' by using the ':all' keyword in the lhs" do
      # this formula is interpreted as '. ~ supp'
      formula = :all ^ :supp
      expect(formula.to_s).to eq "(. ~ supp)"
      rform = R.identity(formula) 
      expect(rform.rclass).to eq "formula"
      expect(rform.typeof).to eq "language"
    end

  end

  #========================================================================================
  context "When modeling with formulas" do

    before(:each) do
      @boston_lm = R.lm(:medv ^ :lstat, data: :Boston)
    end

    it "should obtain data from the model" do
      expect(@boston_lm.coefficients[[1]]).to eq 34.55384
      expect(@boston_lm.coefficients[[2]]).to eq -0.9500494

      expect(@boston_lm.names[[1]]).to eq "coefficients"
      expect(@boston_lm.names[[2]]).to eq "residuals"
      expect(@boston_lm.names[[12]]).to eq "model"
    end

    it "should do predictions (confidence) based on the model" do
      # predict the confidence interval
      conf = R.predict(@boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))),
                       interval: "confidence")
      expect(conf[1, :all][['fit']]).to eq 29.80359
      expect(conf[2, :all][['lwr']]).to eq 24.47413
      expect(conf[3, :all][['upr']]).to eq 20.87461
    end

    it "should do prediction (prediction) based on the model" do
      pred = R.predict(@boston_lm, R.data__frame(lstat: (R.c(5, 10, 15))),
                       interval: "prediction")
      expect(pred[1, :all][['fit']]).to eq 29.80359
      expect(pred[2, :all][['lwr']]).to eq 12.827626
      expect(pred[3, :all][['upr']]).to eq 32.52846
    end

    it "should do multiple linear regression" do
      # Multiple linear regression from ISLR book.  Chapter 3 Lab, pg 113
      lm_fit = R.lm(:medv ^ :lstat + :age, data: :Boston)
      puts lm_fit.summary

      # lm_fit5 = R.lm(:medv ^ E.poly(:lstat, 5), data: :Boston)
      # puts lm_fit5
    end

  end

end
