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

module CorpTheme

  #--------------------------------------------------------------------------------------
  # Defines the plot theme (visualization).  In this theme we remove major and minor
  # grids, borders and background.  We also turn-off scientific notation.
  #--------------------------------------------------------------------------------------

  def self.global_theme
    
    R.options(scipen: 999)  # turn-off scientific notation like 1e+48
    
    # remove major grids
    global_theme = R.theme(panel__grid__major: E.element_blank())
    # remove minor grids
    global_theme = global_theme + R.theme(panel__grid__minor: E.element_blank)
    # remove border
    global_theme = global_theme + R.theme(panel__border: E.element_blank)
    # remove background
    global_theme = global_theme + R.theme(panel__background: E.element_blank)
    # Change axis font
    global_theme = global_theme +
                   R.theme(axis__text: E.element_text(size: 8, color: "#000080"))
    # change color of axis titles
    global_theme = global_theme +
                   R.theme(axis__title: E.element_text(
                             color: "#000080", 
                             face: "bold",
                             size: 8,
                             hjust: 1))
  end
  
end


class ScatterPlot

  attr_accessor :title
  attr_accessor :subtitle
  attr_accessor :caption
  attr_accessor :x_label
  attr_accessor :y_label
  
  #--------------------------------------------------------------------------------------
  # Initialize the plot with the data and the x and y variables
  #--------------------------------------------------------------------------------------

  def initialize(data, x:, y:)
    @data = data
    @x = x
    @y = y
  end

  #--------------------------------------------------------------------------------------
  # Define groupings by color and size
  #--------------------------------------------------------------------------------------

  def group_by(color: nil, size: nil)
    @color_by = color
    @size_by = size
  end

  #--------------------------------------------------------------------------------------
  # Add a smoothing line, and if confidence is true the add a confidence interval, if
  # false does not add the confidence interval
  #--------------------------------------------------------------------------------------

  def add_smoothing_line(method:, confidence: true)
    @method = method
    @confidence = confidence
  end
  
  #--------------------------------------------------------------------------------------
  # Creates the graph title, properly formated for this theme
  # @param title [String] The title to add to the graph
  # @return textGrob that can be included in a graph
  #--------------------------------------------------------------------------------------

  def graph_params(title: "", subtitle: "", caption: "", x_label: "", y_label: "")
    R.labs(
      title: title, 
      subtitle: subtitle, 
      caption: caption,
      y_label: y_label, 
      x_label: x_label, 
    )
  end

  #--------------------------------------------------------------------------------------
  # Prepare the plot's points
  #--------------------------------------------------------------------------------------

  def points
    params = {}
    params[:col] = @color_by if @color_by
    params[:size] = @size_by if @size_by
    R.geom_point(E.aes(params))
  end

  #--------------------------------------------------------------------------------------
  # Plots the scatterplot
  #--------------------------------------------------------------------------------------

  def plot
    R.awt
    
    puts @data.ggplot(E.aes(x: @x, y: @y)) +
      points + 
      R.geom_smooth(method: @method, se: @confidence) +
      R.xlim(R.c(0, 0.1)) +
      R.ylim(R.c(0, 500000)) + 
      graph_params(title: @title,
                   subtitle: @subtitle, 
                   y_label: @y_label, 
                   x_label: @x_label, 
                   caption: @caption) +
      CorpTheme.global_theme
  end
  
end

sp = ScatterPlot.new(~:midwest, x: :area, y: :poptotal)
sp.title = "Midwest Dataset - Scatterplot"
sp.subtitle = "Area Vs Population"
sp.caption = "Source: midwest"
sp.x_label = "Area"
sp.y_label = "Population"
sp.group_by(color: :state, size: :popdensity)    # try sp.group_by(color: :state)
# available methods: "lm", "glm", "loess", "gam"
sp.add_smoothing_line(method: "glm") 
sp.plot


a = gets.chomp
