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

if (!$CONFIG)
  require '../config'
  require 'cantata'
end

describe R::Vector do
  
  context "When creating formulas" do
    
    it "should convert a Ruby Symbol to an R Symbol with '~'" do
      a = ~:cyl
      expect(a.is_a? R::RSymbol).to eq true
      expect a.to_s == "cyl"
    end

    it "binary operators should apply to symbols" do
      # this behaviour is a bit different from R's.  In R this would raise an error
      # with cyl not found
      expect (:cyl + 5).to_s == '.Primitive("+")(cyl, 5L)'
    end

    # Formula objects are special and are very similar to quoted expressions, but
    # they are not really quoted since trying to call R.typeof(<formula>) will
    # evaluate the formula.  We add methods .typeof and .rclass in the Ruby class
    it "formula have typeof and rclass" do
      formula = :cyl + 5
      expect formula.typeof == "language"
      expect formula.rclass == "call"
    end

    it "in formula, only symbols are quoted" do
      # 5 * 10 evaluate to 50 in the formula
      expect(:cyl + 5 * 10).to_s == '.Primitive("+")(cyl, 50L)'
      # define a variable x
      x = 20
      # x is not quoted in the expression
      expect(:cyl + 5 * x).to_s == '.Primitive("+")(cyl, 100L)'
    end

    it "should create a formula without the lhs" do
      puts (~:cyl) + :exp
    end
    
    it "should create formulas with the '=~' operator" do
      expect(:cyl =~ :exp).to_s == '.Primitive("~")(cyl, exp)'
      expect(~:cyl =~ :exp).to_s == '.Primitive("~")(cyl, exp)'
    end

  end

end
