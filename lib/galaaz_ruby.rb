# frozen_string_literal: true

# Interpreter selection for Ruby launchers (bin/gknit, bin/gbookdown, bin/gstudio, Rake).
# Default remains jruby. Override with GALAAZ_RUBY=ruby (or a path).
# JVM flags are applied only when the interpreter is JRuby (see galaaz_jruby.rb).
module GalaazRuby
  def self.interpreter
    bin = ENV['GALAAZ_RUBY'].to_s.strip
    bin.empty? ? 'jruby' : bin
  end

  def self.jruby?(bin = interpreter)
    base = File.basename(bin)
    base == 'jruby' || base.start_with?('jruby.')
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
