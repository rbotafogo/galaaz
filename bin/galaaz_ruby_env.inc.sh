# Galaaz Ruby interpreter selection for bin/* launchers.
# Source from bin/*.sh:  source "$ROOT/bin/galaaz_ruby_env.inc.sh"
#
# Sets:
#   GALAAZ_RUBY_BIN   — interpreter to exec (default: ruby on PATH)
#   GALAAZ_RUBY_J_ARGS — JVM -J flags when that interpreter is JRuby; empty on CRuby
#
# JRuby and CRuby are both first-class. Override with GALAAZ_RUBY=jruby, GALAAZ_RUBY=ruby,
# or a full path. Extra JRuby flags: GALAAZ_JRUBY_OPTS="-J-Xmx4g" (ignored on CRuby).
# CRuby red-arrow uses system Arrow GLib (Apache Arrow APT / libarrow-glib-dev,
# or Omarchy build into /usr/local). Typelibs under /usr/local need GI_TYPELIB_PATH.
if [[ -f "${HOME}/.config/galaaz/arrow-env.sh" ]]; then
  # shellcheck disable=SC1090
  source "${HOME}/.config/galaaz/arrow-env.sh"
else
  if [[ -d /usr/local/lib/girepository-1.0 ]]; then
    export GI_TYPELIB_PATH="/usr/local/lib/girepository-1.0${GI_TYPELIB_PATH:+:${GI_TYPELIB_PATH}}"
  fi
  if [[ -d /usr/local/lib ]]; then
    export LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
  fi
  if [[ -d /usr/local/lib64 ]]; then
    export LD_LIBRARY_PATH="/usr/local/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
  fi
  export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
fi

GALAAZ_RUBY_BIN="${GALAAZ_RUBY:-ruby}"

_galaaz_ruby_base="$(basename -- "$GALAAZ_RUBY_BIN")"
_galaaz_ruby_engine="$("$GALAAZ_RUBY_BIN" -e 'print RUBY_ENGINE' 2>/dev/null || true)"
case "$_galaaz_ruby_base" in
  jruby|jruby.*)
    _galaaz_is_jruby=1
    ;;
  *)
    if [[ "$_galaaz_ruby_engine" == "jruby" ]]; then
      _galaaz_is_jruby=1
    else
      _galaaz_is_jruby=0
    fi
    ;;
esac

if [[ "$_galaaz_is_jruby" -eq 1 ]]; then
  # shellcheck source=galaaz_jruby_env.inc.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/galaaz_jruby_env.inc.sh"
  GALAAZ_RUBY_J_ARGS="$GALAAZ_REQUIRED_JRUBY_J_ARGS ${GALAAZ_JRUBY_OPTS:-}"
  # JAVA_OPTS is exported by galaaz_jruby_env.inc.sh for bundle-exec child JVMs
else
  GALAAZ_REQUIRED_JRUBY_J_ARGS=''
  GALAAZ_RUBY_J_ARGS=''
fi
unset _galaaz_ruby_base _galaaz_ruby_engine _galaaz_is_jruby
