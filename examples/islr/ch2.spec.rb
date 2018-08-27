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

require '../../config'
require 'cantata'

context "ISLR" do

  context "Chapter 2 - Basic Commands" do

    it "Creates a vector" do
      x = R.c(1, 3, 2, 5)
      expect(x[1] == 1).to eq true
      expect(x[3] == 2).to eq true
      expect(x.length == 4).to eq true
    end

    it "should add vectors" do
      x = R.c(1, 6, 2)
      y = R.c(1, 4, 3)
      expect(x.length == 3).to eq true
      z = x + y
      expect(z[1] == 2).to eq true
      expect(z[3] == 5).to eq true
    end

    it "should create matrix by column" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2)
      expect(x.rclass == "matrix").to eq true
      expect(x[1, 1] == 1).to eq true
      expect(x[1, 2] == 3).to eq true
    end
    
    it "should create matrix by row" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2, byrow: true)
      expect(x.rclass == "matrix").to eq true
      expect(x[1, 1] == 1).to eq true
      expect(x[1, 2] == 2).to eq true
    end

    it "should apply a function to all elements of the matrix: ex: sqrt" do
      x = R.matrix(data: R.c(1, 2, 3, 4), nrow: 2, ncol: 2, byrow: true)
      z = x.sqrt
      expect(z[1, 2] == 1.73).to eq true
      expect(z[2, 1] == 1.41).to eq true
    end      

    it "should generate a vector of random normal variables using rnorm" do
      x = R.rnorm(50)
      y = x + R.rnorm(50, mean: 40, sd: 0.1)
      expect(R.cor(x, y) == 0.995).to eq true
    end

    it "should allow to setting the seed" do
      R.set__seed(1303)
      x = R.rnorm(50)
      expect(x[1] == -1.1440).to eq true
      expect(x[2] == 1.3421).to eq true
      expect(x[4] == 0.5364).to eq true
    end

    it "should calculate the mean" do
      R.set__seed(3)
      y = R.rnorm(100)
      expect(y.mean == 0.0110).to eq true
    end

    it "should calculate the variance" do
      R.set__seed(3)
      y = R.rnorm(100)
      expect(y.var == 0.7329).to eq true
      expect(y.var.sqrt == 0.8561).to eq true
      expect(y.sd == 0.8561).to eq true
    end

  end

  context "Chapter 2 - Graphics" do

    it "should plot graphics" do
      # To see the graphic we need to set the device to awt
      R.awt
      x = R.rnorm(100)
      y = R.rnorm(100)
      # plot commands do not work.  Need to work with ggplot or grid
      # qplot uses a similar interface as plot
      # Need to call print at the end of the plot
      R.qplot(x, y,
              xlab: "this is the x-axis",
              ylab: "this is the y-axis",
              main: "Plot of X vs Y")
        .print
      # the graphics dies when the script ends... waiting 3 secs
      # so that the graphic can be seen
      sleep(3)
    end

    # does not print anything... open issue!
    it "should create a jpeg file" do
      R.jpeg("/home/rbotafogo/desenv/cantata/examples/islr/Figure.jpg")
      x = R.rnorm(100)
      y = R.rnorm(100)
      plot = R.qplot(x, y, col: "green")
      R.dev__off
    end

    it "creates sequences with 'seq'" do
      x = R.seq(1, 10)
      expect(x[5] == 5).to eq true
      y = R.seq(-R.pi, R.pi, length: 50)
      expect(y[1] == -3.14159265).to eq true
      expect(y[7] == -2.37222302).to eq true
      expect(y[26] == 0.06411414).to eq true
    end

    it "creates contour plots with ggplot" do
      x = y = R.seq(-R.pi, R.pi, length: 50)
      df = R.data__frame(x: x, y: y)
      f = R.outer(x, y, lambda { |x, y| R.cos(y) / (1 + x**2) })
      
      R.awt
      plot R.ggplot(df, E.aes(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) }))      
    end
    
  end


end
