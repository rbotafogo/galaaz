# frozen_string_literal: true

require 'galaaz'
require 'ggplot'
require 'pp'
require 'irb'
require 'reline'

# --- terminal capability -------------------------------------------------------

def gstudio_colorize?
  return false unless ENV['NO_COLOR'].to_s.empty?
  return false if ENV['TERM'].to_s == 'dumb'
  true
end

def gstudio_version
  spec = Gem.loaded_specs['galaaz']
  return spec.version.to_s if spec

  version_rb = File.expand_path('../../version.rb', __FILE__)
  if File.file?(version_rb)
    load version_rb
    return $version.to_s if defined?($version) && $version
  end

  '?'
end

colorize = gstudio_colorize?
dumb = ENV['TERM'].to_s == 'dumb'

# --- modern IRB defaults (Ruby >= 3.1 / Reline) --------------------------------

IRB.conf[:USE_MULTILINE] = !dumb
IRB.conf[:USE_COLORIZE] = colorize
IRB.conf[:USE_AUTOCOMPLETE] = !dumb
IRB.conf[:AUTO_INDENT] = true
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = File.expand_path('~/.galaaz.history')
# R-like session: expression results are printed by Galaaz/R, not Ruby inspect.
IRB.conf[:ECHO] = false

cyan = colorize ? "\e[36m" : ''
bold = colorize ? "\e[1m" : ''
reset = colorize ? "\e[0m" : ''

IRB.conf[:PROMPT][:CUSTOM] = {
  PROMPT_I: "#{bold}#{cyan}galaaz#{reset} >> ",
  PROMPT_S: '%l>> ',
  PROMPT_C: '.. ',
  PROMPT_N: '.. ',
  RETURN: "=> %s\n"
}
IRB.conf[:PROMPT_MODE] = :CUSTOM

prior_rc = IRB.conf[:IRB_RC]
IRB.conf[:IRB_RC] = lambda do |context|
  prior_rc.call(context) if prior_rc.respond_to?(:call)
  puts "Galaaz #{gstudio_version} on #{RUBY_ENGINE} #{RUBY_VERSION} " \
       "(IRB #{IRB::VERSION}). Tab completes; `history` lists input."
end

# --- session helpers -----------------------------------------------------------

module Kernel
  # Print recent input lines. Optional +count+ limits to the last N entries.
  def history(count = 0)
    history_array =
      if defined?(Reline::HISTORY)
        Reline::HISTORY.to_a
      elsif defined?(Readline::HISTORY)
        Readline::HISTORY.to_a
      else
        []
      end

    if count.is_a?(Integer) && count > 0
      history_array = history_array.last(count)
    end

    puts history_array.join("\n")
    nil
  end
end
