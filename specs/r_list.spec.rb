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

describe R::List do

  #----------------------------------------------------------------------------------------
  context "When creating lists" do

    it "should create an empty list" do
      l = R.list
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
    
    it "should allow creating list of lists" do
      l = R.list(1, 2, 3, R.list(4, 5, 6))
      expect(l.length).to eq 4
    end

    it "should allow mixing different types of objects" do
      l = R.list(R.c(1, 2, 3), R.c(1.0, 2.0, 3.0), R.list(a: 1, b: 2, c: 3),
                 R.complex(real: R.rnorm(5), imag: R.rnorm(5)))
    end

    it "should create lists using sequences" do
      x = R.list(a: (1..10), beta: R.exp(-3..3), logic: R.c(true, false, false, true))
    end

  end

  #----------------------------------------------------------------------------------------
  context "When subsetting a list with '<<' (starts at 0)" do
    
    before(:all) do
      @l = R.list(1, a: 2, b: 3, c: R.list(4, 5, 6))
    end

    it "should return the 'native' (Ruby) element of the list at numeric index" do
      expect(@l << 0).to eq 1
      expect(@l << 1).to eq 2
      expect(@l << 2).to eq 3
    end

    it "should return the 'native' (Ruby) element of the list at named index" do
      expect(@l['a'] << 0).to eq 2
      expect(@l[['a']] << 0).to eq 2
      expect(@l['b'] << 0).to eq 3
    end

    it "should raise an exception (IndexError) if index out of bounds" do
      expect { @l << 4 }.to raise_error(IndexError)
    end

    it "should raise an exception (Argument error) if indexed element is not a vector" do
      expect { @l << 3 }.to raise_error(ArgumentError)
    end

    it "should return nil if named index does not exists" do
      expect(@l['k'] << 0).to eq nil
    end

  end
  
  #----------------------------------------------------------------------------------------
  context "When subsetting a list" do
    
    before(:all) do
      @l = R.list(1, 2, 3, R.list(4, 5, 6))
    end

    it "should subset with [] and positve integer.  Returns a list" do
      expect(@l.length).to eq 4
      # Subsetting a list with [] returns a list 
      expect(@l[1].identical(R.list(1))).to eq true
      # the 4th element of the list is a list of a list
      expect(@l[4].identical(R.list(R.list(4, 5, 6)))).to eq true
    end

    it "should subset with [] and negative integer.  Returns a list" do
      expect(@l[-4].identical(R.list(1, 2, 3))).to eq true
    end

    it "should subset with [] and a vector as index" do
      expect(@l[R.c(4, 1)].identical(R.list(R.list(4, 5, 6), 1))).to eq true
    end

    it "should subset with [[]] and positive integer. Returns the actual element of the list" do
      # to extract an element of a list we need double square (dbk) indexing
      expect(@l[[1]]).to eq 1
      # dbk indexing to get a list
      expect(@l[[4]].identical(R.list(4, 5, 6))).to eq true
    end

    it "can chain subsetting operations" do
      # 1rst element of 4th vector is a list
      expect(@l[[4]][1].identical(R.list(4))).to eq true
      expect(@l[[4]][[1]]).to eq 4
    end
    
    it "should subset with [[]] with multiple indexes" do
      # Note that for a list or other recursive object, the index can be a vector
      # and each element of the vector is applied in turn to the list, the
      # selected component, the selected component of that component, and so on.
      # The result is still a single element.
      expect(@l[[4, 1]]).to eq 4
    end

    it "should subset with 'each' returning every element as if subsetting with '[['" do
      i = 1
      @l.each do |elmt|
        if (i < 4)
          expect(elmt).to eq i
        else
          expect(elmt.identical(R.list(4, 5, 6))).to eq true
        end
        i = i + 1
      end
    end

    it "should subset with 'each_with_index'" do
      @l.each_with_index do |elmt, i|
        if (i < 4)
          expect(elmt).to eq i
        else
          expect(elmt.identical(R.list(4, 5, 6))).to eq true
        end
      end
    end

  end

end
