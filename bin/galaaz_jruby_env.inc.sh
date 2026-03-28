# Galaaz required JVM flags for JRuby (Apache Arrow on Java 9+).
# Source from bin/*.sh:  source "$ROOT/bin/galaaz_jruby_env.inc.sh"
#
# Source of truth in Ruby/Rake: lib/galaaz_jruby.rb (GalaazJRuby::REQUIRED_JRUBY_J_ARGS).
# Optional extra -J flags: export GALAAZ_JRUBY_OPTS="-J-Xmx4g" (space-separated).
GALAAZ_REQUIRED_JRUBY_J_ARGS='-J--add-opens=java.base/java.nio=ALL-UNNAMED'
