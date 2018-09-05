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

require '../../config'
require 'cantata'

context "ISLR" do

  context "Chapter 3 - Subset Selection Methods" do

    before(:each) do
      @hitters = R.Hitters
    end
    
    it "Should access the names of the dataset" do
      expect(@hitters.names[1] == "AtBat").to eq true
      expect(@hitters.names[5] == "RBI").to eq true
      expect(@hitters.names[11] == "CRuns").to eq true
      expect(@hitters.dim == R.c(322, 20)).to eq true
    end

    it "Should count na's using 'R.sum'" do
      expect(R.sum(@hitters.Salary.is__na) == 59).to eq true
      expect(R.sum(@hitters.Salary.is__na)).to eq 59
    end

    it "Should count na's using Ruby Enumerable 'sum'" do
      # method 'sum' is a Ruby Enumerable method.  To count na's we can loop through
      # every element and check if they are na or not.  Note that the return os
      # is__na is an R::Vector, so we need to 'pop' the value to a Ruby value in
      # ordet to apply the '?' method
      expect(@hitters.Salary.sum { |e| ((e.is__na == true).pop) ? 1 : 0 }).to eq 59
    end

    it "should remove missing values with na__omit" do
      @hitters = @hitters.na__omit
      expect(@hitters.dim == R.c(263, 20)).to eq true
      expect(R.sum(@hitters.is__na)).to eq 0
    end
    
  end

end
