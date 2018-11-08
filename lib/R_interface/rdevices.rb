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

require 'singleton'


dir = File.dirname(File.expand_path('.', __FILE__))
src = "#{dir}/capture_plot.R"

R.source(src)

module R

  class Device

    attr_reader :dev, :width, :height, :dpi, :args, :options, :tmp_file, :record
    attr_accessor :file_dir

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def self.create(dev, *options, &block)
      if (dev == 'awt')
        panel = R::Panel.instance
        panel.exec(&block) if block_given?
        panel
      end

      R::Device.new(dev, *options, &block)

    end
   
    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------
    
    def initialize(dev, width: nil, height: nil, dpi: nil, record: false, args: nil,
                   options: nil, tmp_file: R.tempfile, &block)

      @dev = dev
      @width = width
      @height = height
      @dpi = dpi
      @args = args
      @options = options
      @tmp_file = tmp_file
      @record = record
      
      # default arguments
      @file_dir = '.'
      @file_name = "Rplot_#{@width}_#{@height}"

      if block_given?
        begin
          open
          yield
        ensure
          close
        end
      end
      
    end

    #--------------------------------------------------------------------------------------
    # copies the temporary file to the definitive location
    #--------------------------------------------------------------------------------------

    def copy
      
      file = "#{@file_dir}/#{@file_name}.#{ext}"
      puts file
      FileUtils.cp(@tmp_file << 0, file)
      
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------
    
    def open
      
      case @dev
      when 'svg'
        R.svg(@tmp_file)
      when 'awt'
        @record = false
        R.awt
      when 'png'
        # for 'png' @record needs to be true, otherwise the device is not
        # opened.  Don't know why, yet!
        @record = true
        # opens a device for plot recording. 
        if (R._ck_dv(@width, @height, @dev, @args, @dpi, tmp: @tmp_file,
                     record: @record) << 0)
          @dv = R.dev__cur
        else
          raise "Problem opening the device"
        end
      else
        if (R._ck_dv(@width, @height, @dev, @args, @dpi, tmp: @tmp_file,
                     record: @record) << 0)
          @dv = R.dev__cur
        else
          raise "Problem opening the device"
        end
      end
      
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------
    
    def close
      
      case @dev
      when 'svg'
        R.dev__off
      when 'awt'
        R.dev__off
      else
        R.dev__off(@dv)
      end

      copy if @record
      
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def newpage
      R.grid__newpage
    end
    
    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def plot_snapshot
      R._plot_snapshot
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def ext
      R._dev2ext(@dev) << 0
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def save_plot(plot, name, dev, width, height, ext, dpi, options = R.list())
      R._save_plot(plot, name, dev, width, height, ext, dpi, options)
    end
    
  end


  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  class Panel <  Device
    include Singleton

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------
    
    def initialize
      super('awg', width: nil, height: nil, dpi: nil, record: false, args: nil,
            options: nil)
    end

    def exec(&block)
      yield
    end
    
  end
  
end

