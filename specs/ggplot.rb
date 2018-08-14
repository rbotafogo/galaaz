# coding: utf-8
require '../config'
require 'cantata'

# R.library('ggplot2')
Polyglot.eval("R", "library('ggplot2')")
Polyglot.eval("R", "library('grid')")
Polyglot.eval("R", "library('gridExtra')")

module InteropTheme

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.global_theme
    # definir o tema global do gráfico
    # remove major grids
    global_theme = R.theme(panel__grid__major: E.element_blank())
    # remove minor grids
    global_theme = global_theme + R.theme(panel__grid__minor: E.element_blank())
    # remove border
    global_theme = global_theme + R.theme(panel__border: E.element_blank())
    # remove background
    global_theme = global_theme + R.theme(panel__background: E.element_blank())
    # Adjust the title
    global_theme = global_theme + 
                   R.theme(plot__title: E.element_text(size: 8, hjust: 0, color: "#9ecae1"))
    # Change font of axis
    global_theme = global_theme +
                   R.theme(axis__text: E.element_text(size: 8, color: "#000080"))
  end

  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.axis_title
    # Definir o tema do titulo do eixo
    axis_title =
      R.theme(axis__title: E.element_text(color: "#000080", 
                                          face: "bold",
                                          size: 8,
                                          hjust: 1))
  end
  
  #--------------------------------------------------------------------------------------
  #
  #--------------------------------------------------------------------------------------

  def self.bar_theme
    # Definir tema de gráficos de barra
    # remover o eixo y
    gr_bar_theme = R.theme(axis__line__y: E.element_blank(),
                           axis__text__y: E.element_blank(), 
                           axis__ticks__y: E.element_blank())
    # ajustar título dos eixos
    gr_bar_theme = gr_bar_theme + axis_title
  end
  
end

R.awt

plot = R.grid__arrange(
  R.textGrob("Cars wt by mpg"),
  R.ggplot(R.mtcars, E.aes(x: :wt, y: :mpg)) +
  InteropTheme.global_theme + InteropTheme.bar_theme +
  R.geom_bar(stat: "identity", fill: "lightblue")
)

plot.print

sleep(5)

# clear the page
R.grid__newpage

# removes the window and creates a new one
# R.dev__off('')
# R.awt

#Polyglot.eval("R", "dev.off()")
#=end
#R.awt

(R.ggplot(R.mtcars, E.aes(x: :wt, y: :mpg)) +
 R.geom_point('')).print

# Does not work.  ggplot does not know object mtcars.
# R.ggplot(:mtcars, aest)


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
