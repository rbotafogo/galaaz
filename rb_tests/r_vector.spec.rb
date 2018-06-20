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

describe R do

  context "When passing primitive values" do

    # this might change in newer versions of graal. Might not pass future tests
    it "should return an Integer Ruby object if the vector is of length one followed by 'L'" do
      var = R.eval("5L")
      expect(5).to eq var
      expect(var.class).to eq Integer
    end
    
    it "should return a Float Ruby object if the vector is numeric of length one" do
      var = R.eval("4")
      expect(4.0).to eq var
      expect(var.class).to eq Float
    end

    # This has a bug that will be fixed by next version of Truffle
    it "should work with characters" do
      # var = R.eval("'Hello'")
      # p var[0]
      # expect("H").to eq var
    end

    it "should return a string if the vector is a string of length one" do
      # Interop will take a one dimensional array and return the value of the first
      # element.  This might change on a future release. At the present moment, var1
      # becomes a character array with 5 elements
      var1 = R.c("Hello")
      expect(var1.size).to eq 5
      expect(var1[0]).to eq "H"
    end
    
  end

  context "When creating vectors" do
    
    it "should return Vector if the vector has more than 2 elements" do
      int_vect = R.c(1, 2)
      expect(int_vect.length).to eq 2
      expect(int_vect.class).to eq R::Vector
      expect(int_vect.typeof).to eq "integer"

      float_vect = R.c(3.0, 4, 5)
      expect(float_vect.length).to eq 3
      expect(float_vect.class).to eq R::Vector
      expect(float_vect.typeof).to eq "double"
      
      # Here the vector has 3 elements
      str_vect = R.c("Hello", "beautiful", "world!")
      expect(str_vect.length).to eq 3
      expect(str_vect.class).to eq R::Vector
      expect(str_vect.typeof).to eq "character"
    end

    it "should allow creationg of vectors of vectors" do
      vect = R.c(1, 2, 3, R.c(4, 5, 6))
      expect(vect.length).to eq 6
      expect(vect.class).to eq R::Vector
      expect(vect[4]).to eq 4
    end

  end

  context "When subsetting a vector" do
  
    it "should subset vector with integer or negative integer" do
      vect = R.c(1, 2, 3, 4, 5)

      # indexing a vector with a positive interger returns the value at the index
      expect(vect[1]).to eq 1
      expect(vect[3]).to eq 3
      expect(vect[5]).to eq 5

      # a vector when indexed with a negative integer, is a vector without the
      # given element.  So, we are here removing the second element of the vector
      # which leave us with the second element being 3
      expect(vect[-2][2]).to eq 3
    end

    it "should subset a vector with another integer vector" do
      vect = R.c(1, 2, 3, 4, 5)
      expect(vect[R.c(2, 4)][1]).to eq 2
      expect(vect[R.c(2, 4)][2]).to eq 4
      expect(vect[R.c(3, 3)][2]).to eq 3
    end

    it "should allow reordering of elements based on function" do
      vect = R.c(2.1, 4.2, 3.3, 5.4)
      expect(vect[R.order(vect)][2]).to eq 3.3
      expect(vect[R.order(vect)][3]).to eq 4.2
    end

  end

  context "When subset assigning to a vector" do
    
    it "should subset assign with integer" do
      vect = R.c(1, 2, 3, 4, 5)
      expect(vect[2]).to eq 2
      vect[2] = 1000
      expect(vect[2]).to eq 1000
    end

    it "should subset assign to the elements given by another vector" do
      vect = R.c(1, 2, 3, 4, 5)
      vect[R.c(2, 3)] = R.c(1000, 2000)
      puts vect
    end

=begin    
    it "should allow adding elements to the vector" do
      R.eval(<<-R)
         vec = c(2.1, 4.2, 3.3, 5.4);
         print(order(vec));
      R

    end
=end    
  end
end
