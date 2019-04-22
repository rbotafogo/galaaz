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
require 'ggplot'

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
      expect(z[1, 2].all__equal(1.41421356)).to eq true
      expect(z[2, 1].all__equal(1.73205080)).to eq true
    end      

    it "should generate a vector of random normal variables using rnorm" do
      R.set__seed(3)
      x = R.rnorm(50)
      y = x + R.rnorm(50, mean: 40, sd: 0.1)
      expect(R.cor(x, y).all__equal(0.995717314227608)).to eq true
      expect(x.cor(y).all__equal(0.995717314227608)).to eq true
    end

    it "should allow to setting the seed" do
      R.set__seed(1303)
      x = R.rnorm(50)
      expect(x[1].all__equal(-1.14397631)).to eq true
      expect(x[2].all__equal(1.34212936)).to eq true
      expect(x[4].all__equal(0.53639251)).to eq true
    end

    it "should calculate the mean" do
      R.set__seed(3)
      y = R.rnorm(100)
      expect(y.mean.all__equal(0.0110355710)).to eq true
    end

    it "should calculate the variance" do
      R.set__seed(3)
      y = R.rnorm(100)
      
      expect(y.var.all__equal(0.732867501277449)).to eq true
      expect(y.var.sqrt.all__equal(0.856076808047881)).to eq true
      expect(y.sd.all__equal(0.856076808047881)).to eq true
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

    it "should create a jpeg file" do
      R.jpeg("/home/rbotafogo/desenv/galaaz/examples/islr/x_y_rnorm.jpg")
      R.df = R.data__frame(x: R.rnorm(100), y: R.rnorm(100))
      puts R.qplot(:x, :y, data: :df, col: "green")
      R.dev__off
    end

    it "creates sequences with 'seq'" do
      x = R.seq(1, 10)
      expect(x[5] == 5).to eq true
      y = R.seq(-~:pi, ~:pi, length: 50)
      expect(y[1].all__equal(-3.1415926535)).to eq true
      expect(y[7].all__equal(-2.3722230241)).to eq true
      expect(y[26].all__equal(0.0641141357875465)).to eq true
    end
    
=begin
    it "creates contour plots with ggplot" do
      x = y = R.seq(-R.pi, R.pi, length: 50)
      df = R.data__frame(x: x, y: y)
      f = E.outer(:x, :y, lambda { |x, y| R.cos(y) / (1 + x**2) })
      
      R.awt
      print R.ggplot(df, E.aes(:x, :y, z: f))      
      R.dev__off
    end
=end    
  end


end
