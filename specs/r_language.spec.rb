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

describe R::Language do
  
  #========================================================================================
  context "Working with symbols"  do

    it "should assign to an R symbol and retrieve from it" do
      R.cyl = 10
      expect(~:cyl).to eq 10
    end

    it "should allow calling evaluate on the symbol" do
      R.cyl = 10
      expect(R.eval(~:cyl)).to eq 10
    end

  end

  #========================================================================================
  context "Working with expressions"  do

    before(:all) do
      R::Support.eval(<<-R)
        check_type = function(x) {
          print(class(x))
        }

        subs = function(x) {
          substitute(x)
        }

        dep = function(x) {
          deparse(substitute(x))
        }
      R
      
    end
    
    before(:each) do
      @exp1 = :len + :sd         # (len + sd)
      @exp2 = :len - :sd + 5     # ((len - sd) + 5)
      @exp3 = :len + :sd * 5     # (len + (sd * 5))
      
      # those are formulas: have a '^' operator
      @formula1 = :y ^ :len + :sd    # (y ~ (len + sd))
    end

    it "should create expression from a Numeric" do
      expect(R::Expression.build(4).to_s).to eq "4"
      expect(R::Expression.build(4.3).to_s).to eq "4.3"
    end

    it "should create expression from Symbol" do
      expect(R::Expression.build(:c).to_s).to eq "c"
    end
    
    it "should identify a formula from an expression" do
      expect(@exp1.formula?).to eq false
      expect(@formula1.formula?).to eq true
    end

    it "should convert an expression (not fornula) to a quosure" do
      # @TODO: check results!
    end

    it "should be properly interpreted in 'substitute' and 'deparse'" do
      expect(R.dep(:x + :y ** 2)).to eq "(x + (y^2))"
    end

  end
  
  #========================================================================================
  context "Converting expression to rexpression" do

    it "should convert algebraic expressions" do
      expect((R.substitute(:a + 4)).to_s).to eq "(a + 4)"
      expect((R.substitute(:a + 4)).to_s).not_to eq "(a + 5)"
      expect((R.substitute(:a - 4)).to_s).to eq "(a - 4)"
      expect((R.substitute(:a - 4)).to_s).not_to eq "(a + 6)"
      expect((R.substitute(:a / 4)).to_s).to eq "(a/4)"
      expect((R.substitute(:a * 4)).to_s).to eq "(a * 4)"
      expect((R.substitute(:a ** 4)).to_s).to eq "(a^4)"
      expect(R.substitute(:a % 4).to_s).to eq "(a %% 4)"
      expect(R.substitute(:a.mod 4).to_s).to eq "(a %% 4)"
    end

    it "should coerce algebraic expressions" do
      expect((R.substitute(4 + :a)).to_s).to eq "(4 + a)"
      expect((R.substitute(4 / :a)).to_s).to eq "(4/a)"
    end

    it "should convert comparison expressions with binary operators" do
      expect((R.substitute(:a > 4)).to_s).to eq "(a > 4)"
      expect((R.substitute(:a >= 4)).to_s).to eq "(a >= 4)"
      expect((R.substitute(:a < 4)).to_s).to eq "(a < 4)"
      expect((R.substitute(:a <= 4)).to_s).to eq "(a <= 4)"
      expect((R.substitute(:a != 4)).to_s).to eq "(a != 4)"
    end

    it "should convert comparison expressions with binary functions" do
      expect((R.substitute(:a.gt 4)).to_s).to eq "(a > 4)"
      expect((R.substitute(:a.ge 4)).to_s).to eq "(a >= 4)"
      expect((R.substitute(:a.lt 4)).to_s).to eq "(a < 4)"
      expect((R.substitute(:a.le 4)).to_s).to eq "(a <= 4)"
      expect((R.substitute(:a.ne 4)).to_s).to eq "(a != 4)"
    end

    it "should NOT convert '==' to an expression" do
      # '==' should not be redefined in this context, it checks Ruby equality of
      # symbol :a with a number and should be false
      expect(R.substitute(:a == 4).to_s).to_not eq "(a == 4)"
      expect(:a == 4).to eq false
    end

    it "should use '.eql' to create an expression with an equality" do
      expect(R.substitute(:a.eql 4).to_s).to eq "(a == 4)"
    end

    it "should convert logical expressions to rexpressions" do
      expect(R.substitute(:a & 4).to_s).to eq "(a & 4)"
      expect(R.substitute(:a.and 4).to_s).to eq "(a & 4)"
      expect(R.substitute(:a | 4).to_s).to eq "(a | 4)"
      expect(R.substitute(:a.or 4).to_s).to eq "(a | 4)"
    end
    
    it "should convert more complex expressions" do
      expect(R.substitute((((4 * :a).gt 5) + 8).le 3).to_s).to eq "((((4 * a) > 5) + 8) <= 3)"
    end
    
  end

  #========================================================================================
  context "Executing R expressions" do

    it "should execute algebraic expressions" do
      R.a = 10
      expect((R.substitute(:a + 4)).eval).to eq 14
      expect((R.substitute(:a - 4)).eval).to eq 6
      expect((R.substitute(:a / 4)).eval).to eq 2.5
      expect((R.substitute(:a * 4)).eval).to eq 40
      expect((R.substitute(:a ** 4)).eval).to eq 10000
    end

    it "should execute coerced algebraic expressions" do
      R.a = 10
      expect((R.substitute(4 + :a)).eval).to eq 14
      expect((R.substitute(4 - :a)).eval).to eq -6
      expect((R.substitute(4 / :a)).eval).to eq 0.4
      expect((R.substitute(4 * :a)).eval).to eq 40
      expect((R.substitute(4 ** :a)).eval).to eq 1_048_576
    end
    
    it "should eval an R expression in the context of a list" do
      ct = R.list(a: 10, b: 20, c: 30)
      exp = :a + :b * :c
      expect(R.eval(exp, ct)).to eq 610
    end

    it "should eval an R function in the context of a list" do
      R.x = 5
      expect(R.eval(:x + 10)).to eq 15
      ct = R.list(x: 20)
      expect(R.eval(:x + 10, ct)).to eq 30
    end
    
  end
  
=begin
  #========================================================================================
  context "When creating Calls" do

    it "binary operators should apply to symbols" do
      # this behaviour is a bit different from R's.  In R this would raise an error
      # with cyl not found
      expect(:cyl + 5).to_s == '.Primitive("+")(cyl, 5L)'
    end

    it "should properly coerce to language" do
      expect (5 + 5).to_s == '.Primitive("+")(5L, cyl)'
    end

    # Formula objects are special and are very similar to quoted expressions, but
    # they are not really quoted since trying to call R.typeof(<formula>) will
    # evaluate the formula.  We add methods .typeof and .rclass in the Ruby class
    it "formula have typeof and rclass" do
      call = :cyl + 5
      expect call.typeof == "language"
      expect call.rclass == "call"
    end

    it "during calls creation, only symbols are unevaluated" do
      # 5 * 10 evaluate to 50 in the call
      expect(:cyl + 5 * 10).to_s == '.Primitive("+")(cyl, 50L)'
      # define a variable x
      x = 20
      # x is not quoted in the expression
      expect(:cyl + 5 * x).to_s == '.Primitive("+")(cyl, 100L)'
    end

  end
  
=end
    
end
