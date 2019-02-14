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
    
    it "should create formulas with the 'formula' function" do
      formula = R.formula("log(y) ~ a + log(x)")
      # formulas also capture their environment.  When printing the
      # formula, two lines are printed: the first one with the formula
      # and the second one with the environmnet. We are keeping only the
      # first line for comparing with the expected formula
      expect(formula.to_s.lines.first.chomp).to eq "log(y) ~ a + log(x)"
    end

    it "should create formulas with the '.til' function" do
      formula = R.formula("cyl ~ exp")
      expect(formula.to_s.lines.first.chomp).to eq "cyl ~ exp"
      
      formula = (:cyl.til :exp)
      expect(formula.to_s.lines.first.chomp).to eq "cyl ~ exp"
      rform = R.identity(formula)
      expect(rform.typeof).to eq 'language'
      expect(rform.rclass).to eq 'formula'
    end

    it "should create a formula with '.' in the rhs" do
      formula = R.formula("supp ~ .")
      expect(formula.to_s.lines.first.chomp).to eq "supp ~ ."
      
      # this formula is interpreted as 'supp ~ .' In this statement formula
      # is an R::Expression which has infix and prefix notation
      formula = :supp.til :__
      expect(formula.to_s.lines.first.chomp).to eq "supp ~ ."
      expect(formula.rclass).to eq "formula"
      expect(formula.typeof).to eq "language"
    end
    
    it "should create a formula with '.' by using the ':__' keyword in the lhs" do
      formula = R.formula(". ~ supp")
      expect(formula.to_s.lines.first.chomp).to eq ". ~ supp"

      # this formula is interpreted as '. ~ supp'
      formula = :__.til :supp
      expect(formula.to_s.lines.first.chomp).to eq ". ~ supp"
      expect(formula.rclass).to eq "formula"
      expect(formula.typeof).to eq "language"
    end

    it "should create a formula starting with '~' with the ':all' symbol in the lhs" do
      formula = R.formula("~ supp")
      expect(formula.to_s.lines.first.chomp).to eq "~supp"
      
      formula = :all.til :supp
      expect(formula.to_s.lines.first.chomp).to eq "~supp"
      expect(formula.rclass).to eq "formula"
      expect(formula.typeof).to eq "language"
    end

    it "should allow formulas with conditional" do
      formula = R.formula("Sepal.Width ~ Petal.Width | Species")
      expect(formula.to_s.lines.first.chomp).to eq "Sepal.Width ~ Petal.Width | Species"
      
      formula = :Sepal__Width.til :Petal__Width | :Species
      expect(formula.to_s.lines.first.chomp).to eq "Sepal.Width ~ Petal.Width | Species"
    end

    it "should allow creating formulas with functions in the lhs" do
      formula = E.log(:y).til :a + E.log(:x)
      expect(formula.to_s.lines.first.chomp).to eq "log(y) ~ a + log(x)"
    end
    
  end

  #========================================================================================
  context "Formula operators" do

    it "should add multiple independent variables to a formula with '+'" do
      # Use multiple independent variables
      formula = :y.til :x1 + :x2
      expect(formula.to_s.lines.first.chomp).to eq "y ~ x1 + x2"
    end

    it "should ignore objects in an analysis with '-'" do
      # Ignore objects in an analysis
      formula = :y.til :x1 - :x2
      expect(formula.to_s.lines.first.chomp).to eq "y ~ x1 - x2"
    end
    
    it "should create interaction between objects with '*'" do
      # Ignore objects in an analysis
      formula = :y.til :x * :x2
      expect(formula.to_s.lines.first.chomp).to eq "y ~ x * x2"

      # Set seed
      R.set__seed(123)
      
      # Data
      R.x = R.rnorm(5)
      R.x2 = R.rnorm(5)
      R.y = R.rnorm(5)
      
      # Model frame
      model = R.model__frame(formula, data: R.data__frame(x: :x, y: :y, x2: :x2))
      expect(model[1, 1].all__equal(1.22408179743946)).to eq true
      expect(model[1, 3].all__equal(1.71506498688328)).to eq true
      expect(model[3, 2].all__equal(1.55870831414912)).to eq true
      expect(model[5, 1].all__equal(-0.555841134754075)).to eq true
    end

    it "should allow creating formulas with interaction between variables with 'inter'" do
      formula = :y.til :x + :x2 + (:x.inter :x2)
      expect(formula.to_s.lines.first.chomp).to eq "y ~ x + x2 + x:x2"

      # Set seed
      R.set__seed(123)
      
      # Data
      R.x = R.rnorm(5)
      R.x2 = R.rnorm(5)
      R.y = R.rnorm(5)
      
      # Model frame
      model = R.model__frame(formula, data: R.data__frame(x: :x, y: :y, x2: :x2))
      expect(model[1, 1].all__equal(1.22408179743946)).to eq true
      expect(model[1, 3].all__equal(1.71506498688328)).to eq true
      expect(model[3, 2].all__equal(1.55870831414912)).to eq true
      expect(model[5, 1].all__equal(-0.555841134754075)).to eq true
    end

    it "should allow creating formulas with interaction with ':in'" do
      # note that '_' is a method with two arguments ':in' and ':a' and
      # that it is necessary to put the whole expression in parenthesis or
      # add parenthesis on the arguments
      formula = :y.til :a + (:b._ :in, :a)
      expect(formula.to_s.lines.first.chomp).to eq "y ~ a + b %in% a"
    end

  end

  #========================================================================================
  context "When modeling with formulas - Simple linear regression" do

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

  end

  #========================================================================================
  context "Multiple linear regression" do

    it "should do multiple linear regression" do
      # Multiple linear regression from ISLR book.  Chapter 3 Lab, pg 113
      lm_fit = R.lm((:medv.til :lstat + :age), data: :Boston)
      
      # Intercept
      expect(lm_fit.coefficients[[1]].all__equal(33.2227605317)).to eq true
      # lstat
      expect(lm_fit.coefficients[[2]].all__equal(-1.0320685641)).to eq true
      expect(lm_fit.coefficients[['lstat']].all__equal(-1.0320685641)).to eq true
      # age
      expect(lm_fit.coefficients[[3]].all__equal(0.0345443385)).to eq true
    end

    it "should do multiple linear regression with polynomials" do
      lm_fit5 = R.lm((:medv.til E.poly(:lstat, 5)), data: :Boston)

      # Intercept
      expect(lm_fit5.coefficients[[1]].all__equal(22.53280632411)).to eq true
      # Poly 1
      expect(lm_fit5.coefficients[[2]].all__equal(-152.4595487225)).to eq true
      # Poly 3
      expect(lm_fit5.coefficients[[4]].all__equal(-27.0510978864097)).to eq true
      # Poly 5
      expect(lm_fit5.coefficients[[6]].all__equal(-19.2524177100554)).to eq true
    end
    
  end
  
end
