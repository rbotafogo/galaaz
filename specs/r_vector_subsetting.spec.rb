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

  context "When subsetting a Vector" do

    before(:all) do
      @vect = R.c(1, 2, 3, 4, 5)
    end
    
    it "should subset vector with integer obtaining a single element" do
      # indexing a vector with a positive interger returns the value at the index
      expect(@vect[1]).to eq 1
      expect(@vect[3]).to eq 3
      expect(@vect[5]).to eq 5
    end

    it "should subset a vector with a negative integer obtaining a Vector" do
      # a vector when indexed with a negative integer, is a vector without the
      # given element.  So, we are here removing the second element of the vector
      # which leave us with the second element being 3
      expect(@vect[-2].identical(R.c(1, 3, 4, 5))).to eq true
      expect(@vect[-3].identical(R.c(1, 2, 4, 5))).to eq true
    end
      
    it "should subset a vector with another integer vector" do
      expect(@vect[R.c(2, 4)][1]).to eq 2
      expect(@vect[R.c(2, 4)][2]).to eq 4
      expect(@vect[R.c(3, 3)][2]).to eq 3
    end
    
    it "should allow reordering of elements based on function" do
      vect = R.c(2.1, 4.2, 3.3, 5.4)
      expect(vect[R.order(vect)][2]).to eq 3.3
      expect(vect[R.order(vect)][3]).to eq 4.2
    end

    it "should subset with another character vector" do
      x = R.c("m", "f", "u", "f", "f", "m", "m")
      lookup = R.c(m: "Male", f: "Female", u: R::NA)

      res = R.c("Male", "Female", R::NA, "Female", "Female", "Male", "Male")
      res.names = R.c("m", "f", "u", "f", "f", "m", "m") 

      expect(lookup[x].all__equal res).to eq true
    end

    it "should subset with 'each'" do
      i = 1
      @vect.each do |elmt|
        expect(elmt.typeof == 'integer').to eq true
        expect(elmt == i).to eq true
        i += 1
      end
    end

    it "should subset with 'each_with_index'" do
      # note that the index starts at 1, since we are getting back an R::Vector
      # element
      @vect.each_with_index do |elmt, i|
        expect(elmt.typeof == 'integer').to eq true
        expect elmt == i
      end
    end

    it "should subset with 'each(:native)' getting back a native Ruby element (not R::Vector)" do
      # in order to access the internal Ruby element from the R::Vector, use 'each' with
      # the :native keyword
      @vect.each(:native) do |elmt|
        expect(elmt.is_a? Numeric).to eq true
      end
    end

    it "should subset with 'each_with_index(:native)' getting a Ruby element" do
      # when using the :native keyword, indexing starts at 0
      @vect.each_with_index(:native) do |elmt, i|
        expect elmt == i + 1
      end
    end
    
  end
  
  #----------------------------------------------------------------------------------------
  context "When subseting with double square brackets" do
    
    it "should retrieve values the same way as single square brackets" do
      vect = R.c(2.1, 4.2, 3.3, 5.4)
      expect vect[[1]] == 2.1
    end
    
  end
  
  #----------------------------------------------------------------------------------------
  context "When subset assigning to a vector" do
    
    before(:all) do
      @vect = R.c(1, 2, 3, 4, 5)
    end

    it "should subset assign with integer" do
      expect(@vect[2]).to eq 2
      @vect[2] = 1000
      expect @vect[2] == 1000
    end
    
    it "should subset assign to the elements given by another vector" do
      @vect[R.c(2, 3)] = R.c(1000, 2000)
      expect(@vect.identical(R.c(1, 1000, 2000, 4, 5))).to eq true
    end
    
  end
  
end
