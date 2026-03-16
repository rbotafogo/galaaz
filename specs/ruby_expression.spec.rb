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
require 'ggplot'

#========================================================================================
# class Expression in the R module extends Ruby's symbols, so that they can be used in
# forming expressions of the form ':x + :y' or more complex than that.  Those
# expressions will then be converted to R expressions when necessary.
#========================================================================================

describe Symbol do

  #========================================================================================
  context "Working with Ruby expressions"  do
    
    before(:each) do
      R.len = 10
      R.sd = 20
      R.vec = R.c(1, 2, 3, 4)
    end
    
    it "should convert a Ruby symbol into an R symbol with unary '+'" do
      exp = +:len
      expect(exp.class).to eq R::RSymbol
      expect(exp.rclass).to eq "integer"
      expect(exp.typeof).to eq "integer"
      expect(exp.eval).to eq 10
    end

    it "should convert a Ruby symbol into an R symbol with 'expr'" do
      exp = R.expr(:len)
      expect(exp.class).to eq R::RSymbol
      expect(exp.rclass).to eq "integer"
      expect(exp.typeof).to eq "integer"
      expect(exp.eval).to eq 10
    end

    it "should convert 'true' and 'false' to TRUE and FALSE in R" do
      e = R.expr(true)
      expect(e).to eq R.c(true)
      e = R.expr(false)
      expect(e).to eq R.c(false)
    end

    it "should allow binary operations with 'expressions'" do
      e1 = +:len
      e2 = e1 + 5
      expect(e2.eval).to eq R.c(15)
    end

    it "should convert binary operations with Symbols to 'expressions'" do
      e1 = :len + :sd
      expect(e1.to_s).to eq "len + sd"
      expect(e1.class).to eq R::Language
      expect(e1.rclass).to eq "integer"
      expect(e1.eval).to eq 30
    end

    it "should convert longer Ruby expressions to 'expression'" do
      e1 = :len + :sd + 5
      expect(e1.to_s).to eq "len + sd + 5L"
      expect(e1.class).to eq R::Language
      expect(e1.rclass).to eq "integer"
      expect(e1.eval).to eq 35
    end

    it "should operate with all comparison operators" do
      df = R.data__frame(a: (1..5), b: (5..1), c: R.c(5, 3, 1, 4, 1))
      
      e = :a > :b
      expect(e.to_s).to eq "a > b"
      expect(e.eval(df)).to eq R.c(false, false, false, true, true)
      
      e = :a.gt :b
      expect(e.to_s).to eq "a > b"
      expect(e.eval(df)).to eq R.c(false, false, false, true, true)
      
      e = :a >= :b
      expect(e.to_s).to eq "a >= b"
      expect(e.eval(df)).to eq R.c(false, false, true, true, true)
      
      e = :a.ge :b
      expect(e.to_s).to eq "a >= b"
      expect(e.eval(df)).to eq R.c(false, false, true, true, true)
      
      e = :a < :b
      expect(e.to_s).to eq "a < b"
      expect(e.eval(df)).to eq R.c(true, true, false, false, false)
      
      e = :a.lt :b
      expect(e.to_s).to eq "a < b"
      expect(e.eval(df)).to eq R.c(true, true, false, false, false)
      
      e = :a <= :b
      expect(e.to_s).to eq "a <= b"
      expect(e.eval(df)).to eq R.c(true, true, true, false, false)
      
      e = :a.le :b
      expect(e.to_s).to eq "a <= b"
      expect(e.eval(df)).to eq R.c(true, true, true, false, false)
      
      e = :a != :b
      expect(e.to_s).to eq "a != b"
      expect(e.eval(df)).to eq R.c(true, true, false, true, true)
      
      e = :a.ne :b
      expect(e.to_s).to eq "a != b"
      expect(e.eval(df)).to eq R.c(true, true, false, true, true)
      
      e = :a.eq :b
      expect(e.to_s).to eq "a == b"
      expect(e.eval(df)).to eq R.c(false, false, true, false, false)
      
    end

    it "should inline r objects in 'expressions'" do
      e1 = :len + :sd + 5 + R.c(1, 2, 3, 4)
      expect(e1.to_s).to eq "len + sd + 5L + 1:4"
      expect(e1.class).to eq R::Language
      expect(e1.rclass).to eq "integer"
      expect(e1.eval).to eq R.c(36, 37, 38, 39)
      expect(e1.eval).not_to eq R.c(35, 37, 38, 39)
    end

    it "should create assignment expressions with method 'assign'" do
      e = :x.assign :vec * 10
      expect(e.to_s).to eq "x <- vec * 10L"
      expect(e.eval).to eq R.c(10, 20, 30, 40)
      expect(~:x).to eq R.c(10, 20, 30, 40)
    end

    it "should create quoted functions with 'E'" do
      exp = E.sin(:vec)
      expect(exp.to_s).to eq "sin(vec)"
      expect(exp.eval.
               all__equal R.c(0.841470984, 0.909297426, 0.141120008, -0.756802495)).to eq true
    end

    it "should require quoted expression to convert expression to string with 'as_string'" do
      exp = E.expr(:len)
      expect(exp.to_s).to eq "expr(len)"
      expect(exp.as_string).to eq "len"
      expect(exp.is__symbol).to eq true
    end

    it "should be possible to check if an expression is a call" do
      exp = E.expr(E.sin(:x))
      expect(exp.typeof).to eq "language"
      expect(exp.typeof).not_to eq "matrix"
      expect(exp.is__call).to eq true
    end

    it "should be able to subset a call as with lists" do
      x = E.expr(E.read__table("important.csv", row__names: false))
      expect(x.typeof).to eq "language"
      expect(x.is__call).to eq true
      expect(x[[1]].to_s).to eq "read.table"
      expect(x[[2]]).to eq "important.csv"
      expect(x[[3]]).to eq false
      expect(x[["row.names"]]).to eq false
      expect(x[["row.names"]]).not_to eq true
      expect(x.length).to eq 3
      # puts x.row__names  # does not work yet
      # puts x.call_standardise # does not work yet
      # x.header = true   # does not work yet
    end

    it "should allow constructing calls with 'call2'" do
      e = R.call2("mean", x: E.expr(:x), na__rm: true)
      expect(e.to_s).to eq "mean(x = x, na.rm = TRUE)"
      
      #> mean(x = x, na.rm = TRUE)
      # e = call2(E.base::mean, x: E.expr(:x), na__rm: TRUE) # does not work yet
      # puts e
      #> base::mean(x = x, na.rm = TRUE)
      
      e = R.call2("<-", E.expr(:x), 10)
      e.eval
      expect(~:x).to eq 10
    end

    it "should allow executing a function with 'exec'" do
      val = R.exec("mean", x: (1..10), na__rm: true, trim: 0.1)
      expect(val).to eq 5.5

      # using ruby arrays and * in place of !!!(list)
      args = [x: (1..10), na__rm: true, trim: 0.1]
      expect(R.exec("mean", *args)).to eq 5.5

      # using ruby arrays and parameter in the function call. Note however
      # that according to Ruby's rule, the array must come before the hash
      # so R.exec("mean", x: (1..10), *params) is a syntax error
      params = [na__rm: true, trim: 0.1]
      expect(R.exec("mean", *params, x: (1..10))).to eq 5.5
    end
    
  end

  #========================================================================================
  context "Expressions inside functions" do

    it "should allow the use of expression in quoted functions" do
      x = y = R.seq(-~:pi, ~:pi, length: 10)
      df = R.data__frame(x: x, y: y)
      
      # quote the outer function
      e = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })

      # evaluate the expression in the scope of a data frame
      res = e.eval(df)
      expect(res.rclass).to eq "matrix"
      expect(res[1, 1].all__equal -0.091999668).to eq true
    end

    it "should be able to pass an expression to a 'subset'" do
      df = R.data__frame(a: (1..5), b: (5..1), c: R.c(5, 3, 1, 4, 1))
      
      sub = R.subset(df, (:a.eq :b))
      expect(sub.rclass).to eq "data.frame"
      expect(sub[1, 1]).to eq 3
      
      sub = R.subset(df, :a >= 4)
      expect(sub.nrow).to eq 2
      expect(sub.ncol).to eq 3
      expect(sub[1, 1]).to eq 4
      expect(sub[1, 3]).to eq 4
      expect(sub[2, 2]).to eq 1
    end
    
  end

  #========================================================================================
  context "Evaluate data in the context of the ruby instance" do

    before(:each) do
      @df = R.data__frame(a: (1..5), b: (5..1), c: R.c(5, 3, 1, 4, 1))
    end

    it "should access columns of the data frame by name" do
      # Note that we use {a} and not {:a}.  In the context of the @df
      # object 'a' is a call to the method that returns column 'a'
      expect(@df.instance_eval {a}).to eq R.c(1, 2, 3, 4, 5)
      expect(@df.instance_eval {b}).to eq R.c(5, 4, 3, 2, 1)
      expect(@df.instance_eval {c}).to eq R.c(5, 3, 1, 4, 1)
    end
    
    it "should evaluate the expression in the given instance" do
      # Ruby way of evaluation code in the scope of an object.
      val = @df.instance_eval {a.eql 4}
      expect(val).to eq R.c(false, false, false, true, false)

      val = @df.instance_eval {a >= 3}
      expect(val).to eq R.c(false, false, true, true, true)

      val = @df.instance_eval {a.eql b}
      expect(val).to eq R.c(false, false, true, false, false)
    end
    
  end


  #========================================================================================
  context "Tidyverse evaluation" do

    it "should allow passing expressions to ggplot" do
      require 'ggplot'

      # df is a Ruby symbol and ToothGrowth is an R dataframe.  But at this point
      # there is no relationship between the two
      df = ~:ToothGrowth
      dose = df.dose
      dose = dose.as__factor
      
      df2 = R.data__frame(
        R.aggregate(df.len, by: R.list(dose), FUN: :mean),
        R.aggregate(df.len, by: R.list(dose), FUN: :sd)[2]
      )
      
      df2.names = R.c("dose", "len", "sd")

      # pass the expressions ':len - :sd' and ':len + :sd' to the aes function
      f = df2.ggplot(E.aes(x: :dose, y: :len, 
                           ymin: :len - :sd,
                           ymax: :len + :sd))

      # create the graphics and saves it
      R.png("specs/figures/dose_len.png")
      puts f + R.geom_crossbar
      R.dev__off
    end

  end

end
