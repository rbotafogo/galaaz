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

describe R do

  before(:each) do
    # Read the R ToothGrowth variable and assign it to the
    # Ruby instance variable @tooth_growth that will be 
    # available to all Ruby chunks in this document.
    @tooth_growth = ~:ToothGrowth
    
    # convert the dose to a factor
    @tooth_growth.dose = @tooth_growth.dose.as__factor
    
  end
  
  #----------------------------------------------------------------------------------------
  context "Using png device" do
    
    it "should generate png file without arguments" do

      out_file = "specs/figures/no_args.png"
      dir = File.dirname(out_file)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      R.png(out_file)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate png file with width and height" do

      out_file = "specs/figures/width_height.png"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # default 'units' is 'px'
      R.png(out_file, width: 520, height: 520)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate png file with width, height and units 'in'" do

      out_file = "specs/figures/width_height_units1.png"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # set units to inches, needs to specify resolution also
      # using 72 dpi
      R.png(out_file, width: 7, height: 7, units: "in", res: 72)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate png file with width, height and units 'cm'" do

      out_file = "specs/figures/width_height_units2.png"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # set units to cm, needs to specify resolution also,
      # using 72 dpi
      R.png(out_file, width: 7, height: 7, units: "cm", res: 72)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate png file with a background" do

      out_file = "specs/figures/bg.png"
      dir = File.dirname(out_file)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      R.png(out_file, bg: "blue")
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

  end

  #----------------------------------------------------------------------------------------
  context "Using svg device" do
    
    it "should generate svg file without arguments" do

      out_file = "specs/figures/no_args.svg"
      dir = File.dirname(out_file)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      R.svg(out_file)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

=begin    
    # does not work... should not pass width and height to svg file
    it "should generate svg file with width and height" do

      out_file = "specs/figures/width_height.svg"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # default 'units' is 'px'
      R.svg(out_file, width: 520, height: 520)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    
    it "should generate svg file with width, height and units 'in'" do

      out_file = "specs/figures/width_height_units1.svg"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # set units to inches, needs to specify resolution also
      # using 72 dpi
      R.svg(out_file, width: 7, height: 7, units: "in", res: 72)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate svg file with width, height and units 'cm'" do

      out_file = "specs/figures/width_height_units2.svg"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # set units to cm, needs to specify resolution also,
      # using 72 dpi
      R.svg(out_file, width: 7, height: 7, units: "cm", res: 72)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end
=end
    
  #----------------------------------------------------------------------------------------
    it "should generate svg file with a background" do

      out_file = "specs/figures/bg.svg"
      dir = File.dirname(out_file)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      R.svg(out_file, bg: "blue")
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

  end
  
  #----------------------------------------------------------------------------------------
  context "Using jpg device" do
    
    it "should generate jpeg file without arguments" do

      out_file = "specs/figures/no_args.jpeg"
      dir = File.dirname(out_file)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      R.jpeg(out_file)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate jpeg file with width and height" do

      out_file = "specs/figures/width_height.jpeg"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # default 'units' is 'px'
      R.jpeg(out_file, width: 520, height: 520)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate jpeg file with width, height and units 'in'" do

      out_file = "specs/figures/width_height_units1.jpeg"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # set units to inches, needs to specify resolution also
      # using 72 dpi
      R.jpeg(out_file, width: 7, height: 7, units: "in", res: 72)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate jpeg file with width, height and units 'cm'" do

      out_file = "specs/figures/width_height_units2.jpeg"
      dir = File.dirname(out_file)
      
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # set units to cm, needs to specify resolution also,
      # using 72 dpi
      R.jpeg(out_file, width: 7, height: 7, units: "cm", res: 72)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

    it "should generate jpeg file with a background" do

      out_file = "specs/figures/bg.jpeg"
      dir = File.dirname(out_file)

      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      # R.jpeg(out_file, bg: "blue")
      R.jpeg(out_file)
      
      e = @tooth_growth.ggplot(E.aes(x: :dose, y: :len))
      print e + R.geom_boxplot

      R.dev__off

    end

  end


end
