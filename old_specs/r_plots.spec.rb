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

describe R::Plots do

  #----------------------------------------------------------------------------------------
  context "Create a Plot" do

    it "should create a bar plot" do
      dev = R::Device.new('png', width: 5, height: 7, dpi: 300, record: true)

      # opens de device
      dev.open
      # generate the bar plot
      b = R.ggplot(:mpg, E.aes(:fl))
      # prints the plot
      print b + R.geom_bar

      snap = dev.plot_snapshot
      dev.save_plot(snap, 'snapshot', 'png', 5, 7, 'png', 300)
      
      R.grid__newpage(recording: true)
        
      # print a second bar chart
      print b + R.geom_bar(fill: "steelblue", color: "steelblue") +
            R.theme_minimal
      
      # closes the device
      dev.close
    end

    it "should create a bar plot passing a block to the device" do
      # creates the device and pass the plot spec in a block.  No need to
      # worry about opening and closing the device
      dev = R::Device.new('svg', width: 5, height: 7, dpi: 300, record: true) {
        b = R.ggplot(:mpg, E.aes(:fl))
        print b + R.geom_bar

        R.grid__newpage(recording: true)
        
        # print a second bar chart
        print b + R.geom_bar(fill: "steelblue", color: "steelblue") +
              R.theme_minimal
        
      }
    end

  end

end
