begin
  require 'simplecov'

  SimpleCov.start do
    add_filter '/specs/'
    add_filter '/new_bridge_specs/'
  end
rescue LoadError
  # Keep spec bootstrap working even if simplecov is unavailable locally.
end
