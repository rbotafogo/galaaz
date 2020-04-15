 require 'galaaz'
require 'ggplot'
require 'pp'

Pry.config.prompt = proc { |obj, nest_level, _| "galaaz:#{nest_level}> " }
# Pry.config.history.file = '~/.galaaz.history'
Pry.config.editor = "emacsclient"
