# frozen_string_literal: true

# JVM arguments required for every JRuby process that loads Galaaz (Apache Arrow memory
# on Java 9+). Rake and Ruby launchers should use GalaazJRuby.shell_j_arg_string.
#
# Optional extra flags (e.g. -J-Xmx4g): set environment variable GALAAZ_JRUBY_OPTS
# (space-separated; passed through to the shell unquoted).
#
# Bash entrypoints (bin/run_rspec, etc.) source bin/galaaz_jruby_env.inc.sh — keep the
# -J list there identical to REQUIRED_JRUBY_J_ARGS below.
module GalaazJRuby
  REQUIRED_JRUBY_J_ARGS = %w[
    -J--add-opens=java.base/java.nio=ALL-UNNAMED
  ].freeze

  OPTIONAL_ENV = 'GALAAZ_JRUBY_OPTS'

  def self.shell_j_arg_string
    extra = ENV[OPTIONAL_ENV].to_s.strip
    [REQUIRED_JRUBY_J_ARGS.join(' '), extra].reject(&:empty?).join(' ')
  end
end
