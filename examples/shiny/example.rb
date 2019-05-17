require 'galaaz'

R.library('shiny')

ui = R.bootstrapPage(
  R.numericInput('n', 'Number of obs', 100),
  R.plotOutput('plot')
)

build_server = Polyglot.eval("R", <<-R)
  function(code) {
    function(input, output) {
      output$plot <- renderPlot({ code })
    }
  }
R

=begin
server = Proc.new {|input, output|
  output.plot = R.reactive(E.hist(E.runif(input.n)))
}
=end

server = build_server.call(E.hist(E.runif(:input.n)))

R.runApp(R.list(ui: ui, server: server))
