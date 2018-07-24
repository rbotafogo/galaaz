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

require '../config'
require 'cantata'

describe R::Vector do

  #----------------------------------------------------------------------------------------
   context "Arithmetic operators" do

     before(:each) do
       @vec1 = R.c(3, 5.7, 10, 12)
       @vec2 = R.c(2.3, 3, 9, 17)
     end
     
     it "should add two vectors" do
       res = @vec1 + @vec2
       expect(res.all__equal(R.c(5.3, 8.7, 19, 29))).to eq true
     end

     it "should subtract two vectors" do
       res = @vec1 - @vec2
       expect(res.all__equal(R.c(0.7, 2.7, 1.0, -5.0))).to eq true
     end

     it "should multiply two vectors" do
       res = @vec1 * @vec2
       expect(res.all__equal(R.c(6.9, 17.1, 90.0, 204.0))).to eq true
     end

     it "should exponentiate two vectors" do
       res = @vec1 ** @vec2
       expect(res.all__equal(R.c(3**2.3, 5.7**3, 10**9, 12**17))).to eq true
     end

     it "should divide two vectors" do
       res = @vec1 / @vec2
       expect(res.all__equal(R.c(3/2.3, 5.7/3, 10/9.0, 12.0/17))).to eq true
     end

     it "should calculate the modulus of two vectors" do
       res = @vec1 % @vec2
       expect(res.all__equal(R.c(3%2.3, 5.7%3, 10%9.0, 12.0%17))).to eq true
     end

   end

   #----------------------------------------------------------------------------------------
   context "Logical operators" do
     
   end

end
