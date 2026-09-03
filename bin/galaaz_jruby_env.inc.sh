# Galaaz required JVM flags for JRuby (Apache Arrow memory on Java 9+).
# Source from bin/*.sh:  source "$ROOT/bin/galaaz_jruby_env.inc.sh"
#
# Source of truth in Ruby/Rake: lib/galaaz_jruby.rb (GalaazJRuby::JAVA_NIO_ADD_OPENS).
# Optional extra -J flags: export GALAAZ_JRUBY_OPTS="-J-Xmx4g" (space-separated).
#
# JAVA_OPTS is exported so *child* JRuby processes (bundle exec rspec, mise exec)
# get the same opens flag. -J args on the outer command are not inherited by
# bundle exec's second JVM.
GALAAZ_JAVA_NIO_ADD_OPENS='--add-opens=java.base/java.nio=ALL-UNNAMED'
GALAAZ_REQUIRED_JRUBY_J_ARGS="-J${GALAAZ_JAVA_NIO_ADD_OPENS}"

case " ${JAVA_OPTS:-} " in
  *" ${GALAAZ_JAVA_NIO_ADD_OPENS} "*) ;;
  *)
    if [ -n "${JAVA_OPTS:-}" ]; then
      export JAVA_OPTS="${GALAAZ_JAVA_NIO_ADD_OPENS} ${JAVA_OPTS}"
    else
      export JAVA_OPTS="${GALAAZ_JAVA_NIO_ADD_OPENS}"
    fi
    ;;
esac
