# frozen_string_literal: true

# JVM arguments required for every JRuby process that loads Galaaz (Apache Arrow memory
# on Java 9+). Rake and Ruby launchers should use GalaazJRuby.shell_j_arg_string.
#
# The opens flag must be on the *JVM at startup*. `jruby -J--add-opens=... -S bundle exec`
# does not pass it to the child rspec JVM — export JAVA_OPTS instead (see
# +apply_java_opts_env!+ and bin/galaaz_jruby_env.inc.sh).
#
# Optional extra flags (e.g. -J-Xmx4g): set environment variable GALAAZ_JRUBY_OPTS
# (space-separated; passed through to the shell unquoted).
#
# Bash entrypoints (bin/run_rspec, etc.) source bin/galaaz_jruby_env.inc.sh — keep the
# -J list there identical to REQUIRED_JRUBY_J_ARGS below.
module GalaazJRuby
  JAVA_NIO_ADD_OPENS = '--add-opens=java.base/java.nio=ALL-UNNAMED'

  REQUIRED_JRUBY_J_ARGS = %W[
    -J#{JAVA_NIO_ADD_OPENS}
  ].freeze

  OPTIONAL_ENV = 'GALAAZ_JRUBY_OPTS'

  def self.shell_j_arg_string
    extra = ENV[OPTIONAL_ENV].to_s.strip
    [REQUIRED_JRUBY_J_ARGS.join(' '), extra].reject(&:empty?).join(' ')
  end

  # For subprocess JVMs (and so launchers that exec JRuby after requiring this file
  # pick up the flag). Does not change the already-running JVM.
  def self.apply_java_opts_env!
    opts = ENV['JAVA_OPTS'].to_s
    return if opts.split.include?(JAVA_NIO_ADD_OPENS)

    ENV['JAVA_OPTS'] = [JAVA_NIO_ADD_OPENS, opts].reject(&:empty?).join(' ')
  end
end
