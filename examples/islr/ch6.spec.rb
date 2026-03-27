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

context "ISLR" do

  context "Chapter 6 - Subset Selection Methods - page 244" do

    def galaaz_islr_debug(msg)
      STDERR.puts "[DEBUG islr][ch6.spec][#{Time.now.strftime('%H:%M:%S')}] #{msg}"
      STDERR.flush
    end

    before(:each) do
      @hitters = ~:Hitters
    end
    
    it "Should access the names of the dataset" do
      galaaz_islr_debug 'test1 start (names/dim)'
      expect(@hitters.names[1] == "AtBat").to eq true
      expect(@hitters.names[5] == "RBI").to eq true
      expect(@hitters.names[11] == "CRuns").to eq true
      expect(@hitters.dim == R.c(322, 20)).to eq true
      galaaz_islr_debug 'test1 end'
    end

    it "Should count na's using 'R.sum'" do
      galaaz_islr_debug 'test2 start (R.sum)'
      expect(R.sum(@hitters.Salary.is__na) == 59).to eq true
      expect(R.sum(@hitters.Salary.is__na)).to eq 59
      galaaz_islr_debug 'test2 end'
    end

    it "Should count na's using Ruby Enumerable 'sum'" do
      galaaz_islr_debug "test3 start (Ruby Enumerable sum over Salary)"
      yielded = 0
      salary = @hitters.Salary
      galaaz_islr_debug "test3 salary fetched; about to salary.size"
      sz = salary.size
      galaaz_islr_debug "test3 salary.size=#{sz}; about to Salary.sum"
      # method 'sum' is a Ruby Enumerable method.  To count na's we can loop through
      # every element and check if they are na or not.  Note that the return os
      # is__na is an R::Vector, so we need to 'pop' the value to a Ruby value in
      # ordet to apply the '?' method
      got = @hitters.Salary.sum do |e|
        yielded += 1
        galaaz_islr_debug("test3 yield #{yielded}") if yielded % 100 == 0
        (e.is__na == true) ? 1 : 0
      end
      galaaz_islr_debug "test3 end (yielded=#{yielded}, got=#{got})"
      expect(got).to eq 59
    end

    it "should remove missing values with na__omit" do
      galaaz_islr_debug 'test4 start (na__omit)'
      @hitters = @hitters.na__omit
      expect(@hitters.dim == R.c(263, 20)).to eq true
      expect(R.sum(@hitters.is__na)).to eq 0
      galaaz_islr_debug 'test4 end'
    end
    
  end

end
