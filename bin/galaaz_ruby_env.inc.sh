# Galaaz Ruby interpreter selection for bin/* launchers.
# Source from bin/*.sh:  source "$ROOT/bin/galaaz_ruby_env.inc.sh"
#
# Sets:
#   GALAAZ_RUBY_BIN   — interpreter to exec (default: jruby)
#   GALAAZ_RUBY_J_ARGS — JVM -J flags when the interpreter is JRuby; empty on CRuby
#
# Override interpreter:  GALAAZ_RUBY=ruby  or  GALAAZ_RUBY=/path/to/ruby
# Extra JRuby flags:     GALAAZ_JRUBY_OPTS="-J-Xmx4g" (ignored on CRuby)

GALAAZ_RUBY_BIN="${GALAAZ_RUBY:-jruby}"

_galaaz_ruby_base="$(basename -- "$GALAAZ_RUBY_BIN")"
case "$_galaaz_ruby_base" in
  jruby|jruby.*)
    # shellcheck source=galaaz_jruby_env.inc.sh
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/galaaz_jruby_env.inc.sh"
    GALAAZ_RUBY_J_ARGS="$GALAAZ_REQUIRED_JRUBY_J_ARGS ${GALAAZ_JRUBY_OPTS:-}"
    ;;
  *)
    GALAAZ_REQUIRED_JRUBY_J_ARGS=''
    GALAAZ_RUBY_J_ARGS=''
    ;;
esac
unset _galaaz_ruby_base
