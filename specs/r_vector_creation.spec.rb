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

describe R::Vector do
  
  context "When creating vectors" do
    
    it "should create logical Vectors" do
      log_vect = R.c(true, false, true, true)
      expect(log_vect.length).to eq 4
      expect(log_vect.class).to eq R::Vector
      expect(log_vect.typeof).to eq "logical"
      expect(log_vect.mode).to eq "logical"
      expect(log_vect.storage__mode).to eq "logical"
    end

    it "should create a vector from a scalar" do
      vec = R.c(1)
      expect(vec.length).to eq 1
      expect(vec.class).to eq R::Vector
    end
    
    it "should create integer Vectors" do
      # in R, numbers are converted to double.  To get an int one needs to add L after the
      # number 1L is an integer
      int_vect = R.c(1, 2)
      expect(int_vect.length).to eq 2
      expect(int_vect.class).to eq R::Vector
      expect(int_vect.typeof).to eq "integer"
      expect(int_vect.mode).to eq "numeric"
      expect(int_vect.storage__mode).to eq "integer"
    end
    
    it "should create double Vectors" do
      float_vect = R.c(3.0, 4, 5)
      expect(float_vect.length).to eq 3
      expect(float_vect.class).to eq R::Vector
      expect(float_vect.typeof).to eq "double"
      expect(float_vect.mode).to eq "numeric"
      expect(float_vect.storage__mode).to eq "double"
    end
    
    it "should create character Vectors" do
      # Here the vector has 3 elements
      str_vect = R.c("Hello", "beautiful", "world!")
      expect(str_vect.length).to eq 3
      expect(str_vect.class).to eq R::Vector
      expect(str_vect.typeof).to eq "character"
      expect(str_vect.mode).to eq "character"
      expect(str_vect.storage__mode).to eq "character"
    end
    
    it "should create a complex Vector" do
      complex_vec = R.complex(real: R.rnorm(100), imag: R.rnorm(100))
      expect(complex_vec.length).to eq 100
      expect(complex_vec.typeof).to eq "complex"
      expect(complex_vec.mode).to eq "complex"
      expect(complex_vec.storage__mode).to eq "complex"
    end
    
    it "should allow creation of vectors of vectors" do
      vect = R.c(1, 2, 3, R.c(4, 5, 6))
      expect(vect.length).to eq 6
      expect(vect.class).to eq R::Vector
      expect(vect[4]).to eq 4
    end
    
    it "should create vectors with the use of other R functions" do
      # R.rep repeats the given vector
      vec2 = R.rep(R.c("A", "B", "C"), 3)
      # vec2.pp
      # expect(vec2.identical(R.c("A", "B", "C", "A", "B", "C", "A", "B", "C"))).to eq true
      
      # R.table calculates the frequencies of elements
      vec3 = R.c("A", "B", "C", "A", "A", "A", "A", "B", "B")
      table = R.table(vec3)
      # expect(R.c(5, 3, 1).identical table).to eq true
    end
    
  end
  
end

