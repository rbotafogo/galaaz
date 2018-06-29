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

  context "When creating lists" do

    it "should create an empty list" do
      l = R.list('')
      expect(l.length).to eq 0
      expect(l.class).to eq R::List
      expect(l.typeof).to eq "list"
    end
    
    it "should return a list when R.list is called" do
      l = R.list(1, 2)
      expect(l.length).to eq 2
      expect(l.class).to eq R::List
      expect(l.typeof).to eq "list"
    end
    
    it "should allow creating of list of lists" do
      l = R.list(1, 2, 3, R.list(4, 5, 6))
      expect(l.length).to eq 4
    end

  end

  context "When subsetting a list" do
  
    it "should subset a list with integer or negative integer" do
      l = R.list(1, 2, 3, R.list(4, 5, 6))
      expect(l.length).to eq 4
      # the element of a list is also a list
      expect(l[1].identical(R.list(1))).to eq true
      # to extract an element of a list we need double square (dbk) indexing
      expect(l[[1]]).to eq 1
      
      # the 4th element of the list is a list of a list
      expect(l[4].identical(R.list(R.list(4, 5, 6)))).to eq true
      # dbk indexing to get a list
      expect(l[[4]].identical(R.list(4, 5, 6))).to eq true
      # 1rst element of 4th vector is a list
      expect(l[[4]][1].identical(R.list(4))).to eq true
      expect(l[[4]][[1]]).to eq 4

      # negative indexing removes the given element
      expect(l[-4].identical(R.list(1, 2, 3))).to eq true

      # Note that for a list or other recursive object, the index can be a vector
      # and each element of the vector is applied in turn to the list, the
      # selected component, the selected component of that component, and so on.
      # The result is still a single element.
      expect(l[[4, 1]]).to eq 4

      # Need to be consistent with the above notation...
      puts "this needs to be fixed"
      l[R.c(4, 1)].pp

    end
=begin
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
=end
  end
=begin  
=end
=begin  
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

  end
=end
end
