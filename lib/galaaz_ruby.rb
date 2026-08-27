# frozen_string_literal: true

require 'shellwords'

# Interpreter selection for Ruby launchers (bin/gknit, bin/gbookdown, bin/gstudio, Rake).
# Default is `ruby` on PATH (JRuby or CRuby). Override with GALAAZ_RUBY=jruby / ruby / path.
# JVM flags are applied only when the selected interpreter is JRuby (see galaaz_jruby.rb).
module GalaazRuby
  def self.interpreter
    bin = ENV['GALAAZ_RUBY'].to_s.strip
    bin.empty? ? 'ruby' : bin
  end

  def self.jruby?(bin = interpreter)
    base = File.basename(bin.to_s)
    return true if base == 'jruby' || base.start_with?('jruby.')

    engine = `#{Shellwords.escape(bin)} -e 'print RUBY_ENGINE' 2>/dev/null`.to_s.strip
    engine == 'jruby'
  rescue StandardError
    false
  end

  # Shell prefix: "<bin> [jvm-args] -I<lib_path>"
  def self.shell_invocation(lib_path)
    bin = interpreter
    if jruby?(bin)
      require_relative 'galaaz_jruby'
      "#{bin} #{GalaazJRuby.shell_j_arg_string} -I#{lib_path}"
    else
      "#{bin} -I#{lib_path}"
    end
  end
end
