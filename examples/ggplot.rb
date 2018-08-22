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

require '../config'
require 'cantata'

# Polyglot.eval("R", "library('ggplot2')")
# Polyglot.eval("R", "library('grid')")
# Polyglot.eval("R", "library('gridExtra')")

module LightBlueTheme

  #--------------------------------------------------------------------------------------
  # Defines the plot theme (visualization).  In this theme we remove major and minor
  # grids, borders and background.
  #--------------------------------------------------------------------------------------

  def self.global_theme
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
  end

  #--------------------------------------------------------------------------------------
  # Creates the graph title, properly formated for this theme
  # @param title [String] The title to add to the graph
  # @return textGrob that can be included in a graph
  #--------------------------------------------------------------------------------------

  def self.graph_title(title)
    R.textGrob(
      title,
      gp: R.gpar(fontsize: 12, col: "#000080"),
      x: R.unit(0.005, "npc"),
      just: R.c("left", "bottom")
    )
  end

  #--------------------------------------------------------------------------------------
  # Creates the graph subtitle, properly formated for this theme
  # @param subtitle [String] The subtitle to add to the graph
  # @return textGrob that can be included in a graph
  #--------------------------------------------------------------------------------------

  def self.graph_subtitle(subtitle)
    R.textGrob(
      subtitle,
      gp: R.gpar(fontsize: 10, col: "#000080"),
      x: R.unit(0.005, "npc"),
      just: R.c("left", "bottom")
    )
  end
  
  #--------------------------------------------------------------------------------------
  # Defines the axis theme (visualization)
  #--------------------------------------------------------------------------------------

  def self.axis_title
    # format the axis title
    axis_title =
      R.theme(
        axis__title: E.element_text(
          color: "#000080", 
          face: "bold",
          size: 8,
          hjust: 1)
      )
  end
  
  #--------------------------------------------------------------------------------------
  # Define a theme for a bar graph
  #--------------------------------------------------------------------------------------

  def self.bar_theme
    # remove the y axis
    gr_bar_theme = R.theme(
      axis__line__y: E.element_blank,
      axis__text__y: E.element_blank, 
      axis__ticks__y: E.element_blank
    )
    
    # adjust the y axis theme 
    gr_bar_theme = gr_bar_theme + axis_title
  end

  #--------------------------------------------------------------------------------------
  # Define a theme for column graphs
  #--------------------------------------------------------------------------------------

  def self.column_theme
    # remove the x axis
    gr_column_theme = R.theme(
      axis__line__x: E.element_blank, 
      axis__text__x: E.element_blank, 
      axis__ticks__x: E.element_blank
    )
    
    # adjust the x axis theme
    gr_column_theme = gr_column_theme + axis_title
  end
  
end

R.awt

plot = R.grid__arrange(
  LightBlueTheme.graph_title("Cars: wt x mpg"),
  LightBlueTheme.graph_subtitle("1974 Motor Trend US magazine"),
  R.ggplot(R.mtcars, E.aes(x: :wt, y: :mpg)) +
  LightBlueTheme.global_theme + # LightBlueTheme.bar_theme +
  R.geom_bar(stat: "identity", fill: "lightblue"),
  ncol: 1,
  heights: R.c(0.050, 0.025, 0.85, 0.05)
)

plot.print

=begin
sleep(5)

# clear the page
R.grid__newpage

# removes the window and creates a new one
# R.dev__off('')
# R.awt

(R.ggplot(R.mtcars, E.aes(x: :wt, y: :mpg)) +
 R.geom_point('')).print
=end

a = gets.chomp


=begin
# Add border around the plot
# global_theme = global_theme + theme(plot.background = element_rect(colour = "black", fill=NA, size=1))

# Definir tema de gráficos de colunas
# remover o eixo x
gr_column_theme = theme(axis.line.x = element_blank(), 
                        axis.text.x = element_blank(), 
                        axis.ticks.x = element_blank())

# ajustar título dos eixos
gr_column_theme = gr_column_theme + axis_title

# Definir tema para gráfico composto
gr_comp_theme = axis_title

br_acc = function(valor) {
  accounting(valor, big.mark = ".", decimal.mark=",")
}
=end
