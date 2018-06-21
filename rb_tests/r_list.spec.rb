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
    
    it "should return a list when R.list is called" do
      l = R.list(1, 2)
      expect(l.length).to eq 2
      expect(l.class).to eq R::List
      expect(l.typeof).to eq "list"
    end
    
#=begin
    it "should allow creationg of list of lists" do
      l = R.list(1, 2, 3, R.list(4, 5, 6))
      l.pp
      # p l.to_s2
      l[4].pp
      l[[4]].pp
      l[[4]][2].pp
      expect(l.length).to eq 4
      # expect(l.class).to eq R::List
      # expect(l[4][1]).to eq 4
    end
#=end
  end
=begin
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
