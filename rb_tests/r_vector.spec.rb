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
      var = R::Support.eval("5L")
      expect(5).to eq var
      expect(var.class).to eq Integer
    end
    
    it "should return a Float Ruby object if the vector is numeric of length one" do
      var = R::Support.eval("4")
      expect(4.0).to eq var
      expect(var.class).to eq Float
    end

    # This has a bug that will be fixed by next version of Truffle
    it "should work with characters" do
      # var = R::Support.eval("'Hello'")
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
  describe R::Vector do
    
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
  
=begin    
it "should allow adding elements to the vector" do
      R.eval(<<-R)
         vec = c(2.1, 4.2, 3.3, 5.4);
         print(order(vec));
      R

    end
=end    
end

