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

  context "When assigning attributes to a Vector" do

    before(:all) do
      @vect = R.c(1, 2, 3, 4, 5, 6)
    end
    
    it "should assign names to vectors" do
      # set names
      @vect.names = R.c("a", "b", "c", "d", "e", "f")
      expect(@vect.names.identical(R.c("a", "b", "c", "d", "e", "f"))).to eq true
    end
    
    it "should assign a dim to vector" do
      # set dim
      @vect.dim = R.c(3, 2)
      expect(@vect.dim[1]).to eq 3
      expect(@vect.dim[2]).to eq 2
    end

    it "should assign row.names to a vector with dimention" do
      @vect.dim = R.c(3, 2)
      # set row.names
      @vect.row__names = R.c("A", "B", "C")
      expect(@vect.row__names.identical(R.c("A", "B", "C")))
      # note that when accessing row__names[2] we are getting a native ruby object
      # and not a vector.  This might change in future versions
      expect(@vect.row__names[2]).to eq "B"
    end

    it "should set the class of the object using rclass" do
      # set the R class.  Note that we need to use rclass instead of class, since
      # class is a Ruby keyword 
      @vect.rclass = "myClass"
      expect(@vect.rclass).to eq "myClass"
    end

    it "should set the attribute of a Vector using attr" do
      # the other alternative is to use method attr to change the attribute
      @vect.attr = {which: "class", value: "newClass"}
      expect(@vect.rclass).to eq "newClass"
    end
      
    it "should allow changing an element of a vector attribute" do
      pending "Need to implement new function for this"
      # set names
      @vect.names = R.c("a", "b", "c", "d", "e", "f")
      @vect.names[2] = "hello"
      expect(@vect.names[2]).to eq "hello"
    end
    
  end

  context "When passing named arguments" do

    it "Named arguments should become the names of the vector" do
      vect = R.c(a: 1, b: 2, c: 3, d: 4)
      expect(vect.names.identical(R.c("a", "b", "c", "d"))).to eq true
    end
    
    it "should allow adding names to sub-vectors" do
      vect = R.c(1, 2, 3, a: R.c(1, 2, 3), b: 5, c: 6)
      expect(vect.names.identical(R.c("", "", "", "a1", "a2", "a3", "b", "c"))).to eq true
    end

  end

end
