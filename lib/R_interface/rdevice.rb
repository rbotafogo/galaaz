# -*- coding: utf-8 -*-
# R::Device: Ruby wrapper for Galaaz plot devices (png, svg, etc.).
# Uses base R graphics and evaluate::plot_snapshot; no R package "device" required.
require 'tmpdir'

module R
  class Device
    def initialize(type, width: 480, height: 480, dpi: 72, record: true, &block)
      @type = type.to_s
      @width = width
      @height = height
      @dpi = dpi
      @record = record
      @block = block
      @dev_path = nil
      @opened = false
    end

    def open
      return if @opened
      dir = File.join(Dir.tmpdir, "galaaz_device_#{Process.pid}")
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      @dev_path = File.join(dir, "dev_#{object_id}.#{@type == 'svg' ? 'svg' : 'png'}")
      w_px = (@width * @dpi).to_i
      h_px = (@height * @dpi).to_i
      if @type == 'svg'
        R.bridge.eval_r("svg('#{@dev_path.gsub("'", "\\\\'")}', width = #{@width}, height = #{@height})")
      else
        R.bridge.eval_r("png('#{@dev_path.gsub("'", "\\\\'")}', width = #{w_px}, height = #{h_px}, res = #{@dpi})")
      end
      @opened = true
      yield if block_given?
    end

    def close
      return unless @opened
      R.dev__off
      @opened = false
    end

    def plot_snapshot
      R.evaluate_plot_snapshot
    end

    def save_plot(plot, name, dev_type, width, height, ext, dpi)
      R.galaaz_save_plot(plot, name, dev_type, width, height, ext, dpi)
    end

    def self.new(type, width: 480, height: 480, dpi: 72, record: true, &block)
      inst = allocate
      inst.send(:initialize, type, width: width, height: height, dpi: dpi, record: record, &block)
      if block_given?
        inst.open
        block.call
        inst.close
      end
      inst
    end
  end
end
