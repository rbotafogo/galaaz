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

     it "should apply unary minus to all elements of a vector" do
       expect((-@vec1).all__equal(R.c(-3, -5.7, -10, -12))).to eq true
     end
     
   end

   #----------------------------------------------------------------------------------------
   context "Comparison operators" do

     it "should check vectors for equality / inequality" do
       vec1 = R.c(1, 2)
       vec2 = R.c(1, 2)
       vec3 = R.c(0, 2)

       expect((vec1 == vec2).all__equal(R.c(true, true))).to eq true
       expect((vec1 != vec2).all__equal(R.c(false, false))).to eq true
       expect((vec1 == vec3).all__equal(R.c(false, true))).to eq true
     end

     it "should check vectors for <, <=, >, >=" do
       vec1 = R.c(1, 2, 3)
       vec2 = R.c(0, 4, 3)

       expect((vec1 < vec2).all__equal(R.c(false, true, false))).to eq true
       expect((vec1 <= vec2).all__equal(R.c(false, true, true))).to eq true
       expect((vec1 > vec2).all__equal(R.c(true, false, false))).to eq true
       expect((vec1 >= vec2).all__equal(R.c(true, false, true))).to eq true
     end

   end

   #----------------------------------------------------------------------------------------
   context "Logical operators" do

     before(:each) do
       @vec1 = R.c(true, true, false, true)
       @vec2 = R.c(true, false, false, false)
     end
     
     it "should negate a vector" do
       expect((!@vec1).all__equal(R.c(false, false, true, false))).to eq true
     end

     it "should 'and' and 'or' two vectors" do
       expect((@vec1 & @vec2).all__equal R.c(true, false, false, false)).to eq true
       expect((@vec1 | @vec2).all__equal R.c(true, true, false, true)).to eq true
     end
     
   end

   #----------------------------------------------------------------------------------------
   context "Access from Ruby" do
     
     before(:each) do
       @vec1 = R.c(3, 5.7, 10, 12)
       @vec2 = R.c(2.3, 3, 9, 17)
     end

     it "Should retrieve Ruby values from a vector with '<<'" do
       # subsetting a vector with '[' and '[[' returns an R::Vector, not a Ruby object
       # Use the '<<' operator to retrieve an element of the R::Vector as a Ruby
       # object
       expect(@vec1[1].is_a? R::Vector).to eq true
       expect((@vec1 << 1).is_a? Numeric).to eq true
       # Note, however, that indexing still follows R indexing, i.e., starts at 1
       expect((@vec1 << 1)).to eq 3
       expect((@vec1 << 3)).to eq 10
     end

     it "should treat R::Vector as an Enumerable" do
       # each 'value' is an R::Vector, with only 1 element.  In order to use Ruby 'sum'
       # we need to extract the value as a Ruby Numeric with << 1
       expect(@vec1.sum { |value| value << 1 }).to eq 30.7
     end

     it "should implement 'pop' to extract the first element of an R::Vector" do
       # pop is equivalent to '<< 1'
       expect(@vec1.pop).to eq 3
     end

     it "should allow storage and retrieval of Ruby Objects in R data structure" do
       pending "Add classes to R::Vector"
       class RData
         def val
           5
         end
       end
       
       vec3 = R.c(RData.new, RData.new)
       p vec3 << 1
       # expect(vec3.pop.is_a? Array).to eq true
       # expect(vec3.pop[0] == 1).to eq true
     end
   end
   
end
