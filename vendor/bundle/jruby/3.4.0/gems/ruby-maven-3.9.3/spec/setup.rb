$LOAD_PATH.unshift File.expand_path( '../../lib', __FILE__ )

ENV["MT_NO_PLUGINS"] = "true"

require 'minitest/autorun'
