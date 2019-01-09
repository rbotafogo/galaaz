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

#========================================================================================
# class Expression in the R module extends Ruby's symbols, so that they can be used in
# forming expressions of the form ':x + :y' or more complex than that.  Those
# expressions will then be converted to R expressions when necessary.
#========================================================================================

describe R::Expression do

  #========================================================================================
  context "Working with Ruby expressions"  do
    
    before(:each) do
      @exp1 = :len + :sd         # (len + sd)
      @exp2 = :len - :sd + 5     # ((len - sd) + 5)
      @exp3 = :len + :sd * 5     # (len + (sd * 5))
      
      # those are formulas: have a '^' operator
      @formula1 = :y ^ :len + :sd    # (y ~ (len + sd))
    end

    it "should create expression in infix notation" do
      expect(@exp1.infix).to eq "(len + sd)"
      expect(@exp2.infix).to eq "((len - sd) + 5)"
      expect(@exp3.infix).to eq "(len + (sd * 5))"
      # expect(@formula1.infix).to eq "(y ~ (len + sd))"
    end

  end
  
end
