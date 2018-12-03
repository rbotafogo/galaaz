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
src = "#{dir}/rdevices.R"

R.source(src)

module R

  class Device

    attr_reader :dev_type, :filename, :width, :height, :dpi, :record,
                :args, :options, :tmp_file, 
                :dev_number
    attr_accessor :file_dir

    
    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def self.list
      R.dev__list
    end
    
    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------
    
    def initialize(dev_type, filename: nil, file_dir: '.', width: nil, height: nil,
                   dpi: nil, record: false, args: nil, options: nil, tmp_file: nil)

      @dev_type = dev_type
      @filename = filename
      @width = width
      @height = height
      @dpi = dpi
      # TODO: Needs to allow false, but truffle is crashing when false. When it is
      # fixed, just change to @record = record
      @record = true
      
      @args = args
      @options = options
      @tmp_file = tmp_file
      
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def open
      
      case @dev_type
           
      when 'svg'
      when 'awt'
        R.awt(width: @width, height: @height)
        @record ? R.dev__control(displaylist: 'enable') :
          R.dev__control(displaylist: 'inhibit')
        @dev_number = R.dev__cur
      when 'png'
        R.png(filename: @filename, width: @width, height: @height, units: 'in', res: dpi)
      when 'jpg'
      when 'bmp'
      else
        raise "Device type #{@dev_type} not allowed"
      end
      
    end
    
    #--------------------------------------------------------------------------------------
    # Opens the device, evaluates the given graphics block expressions and closes the
    # device at the end of execution
    #--------------------------------------------------------------------------------------
    
    def eval(&block)
        
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
    
    def close
      R.dev__off(which: @dev_number)
      # copy if @record
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
      R.knitr_plot_snapshot
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def ext
      R.knitr_dev2ext(@dev) << 0
    end

    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------

    def save_plot(plot, name, dev, width, height, ext, dpi, options = R.list())
      R.knitr_save_plot(plot, name, dev, width, height, ext, dpi, options)
    end
    
  end


  #--------------------------------------------------------------------------------------
  # 
  #--------------------------------------------------------------------------------------
  
  class Panel < Device
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

=begin
    #--------------------------------------------------------------------------------------
    # 
    #--------------------------------------------------------------------------------------
    
    def open2
      
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
=end
