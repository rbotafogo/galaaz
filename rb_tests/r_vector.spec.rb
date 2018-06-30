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

  #----------------------------------------------------------------------------------------
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

  #----------------------------------------------------------------------------------------
  context "When creating vectors" do

    it "should create logical Vectors" do
      log_vect = R.c(true, false, true, true)
      expect(log_vect.length).to eq 4
      expect(log_vect.class).to eq R::Vector
      expect(log_vect.typeof).to eq "logical"
    end
    
    it "should create int Vectors" do
      int_vect = R.c(1, 2)
      expect(int_vect.length).to eq 2
      expect(int_vect.class).to eq R::Vector
      expect(int_vect.typeof).to eq "integer"
    end

    it "should create double Vectors" do
      float_vect = R.c(3.0, 4, 5)
      expect(float_vect.length).to eq 3
      expect(float_vect.class).to eq R::Vector
      expect(float_vect.typeof).to eq "double"
    end
    
    it "should create character Vectors" do
      # Here the vector has 3 elements
      str_vect = R.c("Hello", "beautiful", "world!")
      expect(str_vect.length).to eq 3
      expect(str_vect.class).to eq R::Vector
      expect(str_vect.typeof).to eq "character"
    end

    it "should create a complex Vector" do
      complex_vec = R.complex(real: R.rnorm(100), imag: R.rnorm(100))
      expect(complex_vec.length).to eq 100
      expect(complex_vec.typeof).to eq "complex"
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
    
    it "should allow adding names to vector elements" do
      vect = R.c(1, 2, 3, a: R.c(1, 2, 3), b: 5, c: 6)
      expect(vect.names.identical(R.c("", "", "", "a1", "a2", "a3", "b", "c"))).to eq true
    end

    #--------------------------------------------------------------------------------------
    #
    #--------------------------------------------------------------------------------------

    it " should match two vectors with %in%" do

      vec1 = R.c(1, 2, 3, 4)
      vec2 = R.c(1, 2, 3, 4)
      vec3 = R.c(3, 4, 5)
      vec4 = R.c(4, 5, 6, 7)
      
      # R has functions defined with '%%' notation.  In order to access those functions
      # from SciCom we use the '._' method with two arguments, the first argument is the
      # name of the function, for instance, function %in%, the name of the method is ':in'
      # Ex: vec1 %in% vec2 => vec1._ :in, vec2 
      expect((vec1._ :in, vec2).identical(R.c(true, true, true, true))).to eq true
      expect((vec1._ :in, vec3).identical(R.c(false, false, true, true))).to eq true
      expect((vec2._ :in, vec4).identical(R.c(false, false, false, true))).to eq true
      
    end

  end

  #----------------------------------------------------------------------------------------
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

  #----------------------------------------------------------------------------------------
  context "When subseting with double square brackets" do

    it "should retrieve values the same way as single square brackets" do
      vect = R.c(2.1, 4.2, 3.3, 5.4)
      expect(vect[[1]]).to eq 2.1
    end
    
  end
  
  #----------------------------------------------------------------------------------------
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
      expect(vect.identical(R.c(1, 1000, 2000, 4, 5))).to eq true
    end

  end

  #----------------------------------------------------------------------------------------
  context "When assigning attributes to a vector" do

    it "should assign attributes to vectors" do
      vect = R.c(1, 2, 3, 4, 5, 6)

      # set names
      vect.names = R.c("a", "b", "c", "d", "e", "f")
      expect(vect.names.identical(R.c("a", "b", "c", "d", "e", "f"))).to eq true

      # set dim
      vect.dim = R.c(3, 2)
      expect(vect.dim[1]).to eq 3
      expect(vect.dim[2]).to eq 2

      # set row.names
      vect.row__names = R.c("A", "B", "C")
      expect(vect.row__names.identical(R.c("A", "B", "C")))
      # note that when accessing row__names[2] we are getting a native ruby object
      # and not a vector.  This might change in future versions
      expect(vect.row__names[2]).to eq "B"
      
      # set the R class.  Note that we need to use rclass instead of class, since
      # class is a Ruby keyword 
      vect.rclass = "myClass"
      expect(vect.rclass).to eq "myClass"

      # the other alternative is to use method attr to change the attribute
      vect.attr = {which: "class", value: "newClass"}
      expect(vect.rclass).to eq "newClass"
      
      #
      vect.names[2] = "Hello"
      expect(vect.names[2]).to eq "Hello"
      
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
