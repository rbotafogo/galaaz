# -*- coding: utf-8 -*-
# R::Device: Ruby wrapper for Galaaz plot devices (png, svg, etc.).
# Uses base R graphics and evaluate::plot_snapshot; no R package "device" required.
require 'tmpdir'
require 'fileutils'

module R
  class Device
    def ensure_plot_helpers!
      R.bridge.eval_r(<<~RCODE)
        if (!exists("evaluate_plot_snapshot", envir = .GlobalEnv, inherits = FALSE)) {
          .GlobalEnv$evaluate_plot_snapshot <- function() {
            grDevices::recordPlot()
          }
        }
        if (!exists("galaaz_save_plot", envir = .GlobalEnv, inherits = FALSE)) {
          .GlobalEnv$galaaz_save_plot <- function(path, dev_type, width, height, dpi) {
            if (dev_type == "png") {
              do.call(grDevices::dev.copy, list(
                device = grDevices::png,
                filename = path,
                width = width,
                height = height,
                units = "in",
                res = dpi
              ))
            } else if (dev_type == "svg") {
              do.call(grDevices::dev.copy, list(
                device = grDevices::svg,
                filename = path,
                width = width,
                height = height
              ))
            } else if (dev_type == "pdf") {
              do.call(grDevices::dev.copy, list(
                device = grDevices::pdf,
                file = path,
                width = width,
                height = height
              ))
            } else {
              stop(paste("unsupported dev_type:", dev_type))
            }
            grDevices::dev.off()
            path
          }
        }
        invisible(NULL)
      RCODE
    end

    def initialize(type, width: 480, height: 480, dpi: 72, record: true, &block)
      @type = type.to_s
      @width = width
      @height = height
      @dpi = dpi
      @record = record
      @block = block
      @dev_path = nil
      @opened = false
      @last_save_target = nil
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
      if @last_save_target && @dev_path && File.exist?(@dev_path)
        FileUtils.cp(@dev_path, @last_save_target)
      end
    end

    def plot_snapshot
      ensure_plot_helpers!
      R.evaluate_plot_snapshot
    end

    def save_plot(plot, name, dev_type, width, height, ext, dpi)
      out_name = "#{name}.#{ext}"
      target = out_name.start_with?('/') ? out_name : File.join(Dir.pwd, out_name)
      if @opened
        # Persist current page and reopen the device to keep plotting.
        R.dev__off
        @opened = false
        if @dev_path && File.exist?(@dev_path) && File.size(@dev_path).to_i > 0
          FileUtils.cp(@dev_path, target)
        end
        open
        @last_save_target = nil
      elsif !@opened && @dev_path && File.exist?(@dev_path) && File.size(@dev_path).to_i > 0
        @last_save_target = target
        FileUtils.cp(@dev_path, target)
      end

      out_name
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
