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

describe R::Matrix do

  #----------------------------------------------------------------------------------------
  context "Matrices" do

    it "Should create a matrix by column" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2)
      expect(x[1, 1] == 1).to eq true
      expect(x[1, 2] == 3).to eq true
      expect(x.dim == R.c(2, 2)).to eq true
    end
    
    it "Should create a matrix by row" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2, byrow: true)
      expect(x[1, 1] == 1).to eq true
      expect(x[1, 2] == 2).to eq true
      expect(x.dim == R.c(2, 2)).to eq true
    end

    it "Should add matrices" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2)
      y = R.matrix(data: R.c(2, 4, 6, 8), nrow: 2, ncol: 2)
      z = x + y
      expect(z[1, 1] == 3).to eq true
      expect(z[2, 2] == 12).to eq true
    end
    
    it "Should subtract matrices" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2)
      y = R.matrix(data: R.c(2, 4, 6, 8), nrow: 2, ncol: 2)
      z = y - x
      expect(z[1, 1] == 1).to eq true
      expect(z[2, 2] == 4).to eq true
    end

    it "should multiply by a scalar" do
      y = R.matrix(data: R.c(2, 4, 6, 8), nrow: 2, ncol: 2)
      z = y * 10
      expect(z[1, 1] == 20).to eq true
      expect(z[2, 1] == 40).to eq true
    end

    it "should divide a scalar by a matrix" do
      y = R.matrix(data: R.c(2, 4, 6, 8), nrow: 2, ncol: 2)
      z = 10/y
      expect(z).to eq R.matrix(data: R.c(10/2.0, 10/4.0, 10/6.0, 10/8.0), nrow: 2, ncol: 2)
    end

    it "should apply a function to all elements of the matrix: ex: sqrt" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2, byrow: true)
      z = x.sqrt
      expect(z[1, 2].all__equal(1.41421356)).to eq true
      expect(z[2, 1].all__equal(1.73205080)).to eq true
    end      

  end

end
