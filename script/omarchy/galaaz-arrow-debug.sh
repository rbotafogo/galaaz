#!/bin/bash
# Stepwise Arrow/Stage-B diagnostics for Omarchy.
# Does NOT install by default — prints where things stand and what would run.
#
# Usage:
#   omarchy-galaaz-arrow-debug           # status (safe)
#   omarchy-galaaz-arrow-debug status
#   omarchy-galaaz-arrow-debug probe     # light checks + write report
#   omarchy-galaaz-arrow-debug last-log  # show build log tails + dmesg OOM
#   omarchy-galaaz-arrow-debug install   # run omarchy-galaaz-add arrow with tracing
#
# Report: ~/.local/share/galaaz/arrow-debug.log
set -uo pipefail

LOG_DIR="${HOME}/.local/share/galaaz"
REPORT="${LOG_DIR}/arrow-debug.log"
BUILD_LOG="${LOG_DIR}/arrow-glib-build.log"
TRACE="${LOG_DIR}/arrow-install-trace.log"
mkdir -p "${LOG_DIR}"

export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
export PATH="${HOME}/.local/bin:${PATH}"

CMD="${1:-status}"

trace() {
  # shellcheck disable=SC3037
  echo -e "[$(date -Iseconds)] $*" | tee -a "${REPORT}"
  sync 2>/dev/null || true
}

section() {
  echo | tee -a "${REPORT}"
  trace "======== $* ========"
}

have() { command -v "$1" >/dev/null 2>&1; }

run_status() {
  : >"${REPORT}"
  section "galaaz arrow debug (status)"
  trace "host: $(uname -a 2>/dev/null || true)"
  trace "user: $(id -un) home=${HOME}"
  trace "PATH=${PATH}"

  section "memory / disk"
  if [[ -r /proc/meminfo ]]; then
    awk '/MemTotal:|MemAvailable:|SwapTotal:|SwapFree:/ {printf "  %s\n", $0}' /proc/meminfo | tee -a "${REPORT}"
  fi
  df -h "${HOME}" /tmp /usr/local 2>/dev/null | tee -a "${REPORT}" || true
  free -h 2>/dev/null | tee -a "${REPORT}" || true

  section "tools"
  for c in pacman omarchy-pkg-add pkg-config meson ninja cmake curl sudo systemd-run \
           galaaz omarchy-galaaz-add ruby gem Rscript mise; do
    if have "${c}"; then
      trace "OK  ${c}: $(command -v "${c}")"
    else
      trace "MISS ${c}"
    fi
  done

  section "pkg-config Arrow"
  if have pkg-config; then
    trace "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
    if pkg-config --exists arrow; then
      trace "OK  arrow: $(pkg-config --modversion arrow)"
    else
      trace "MISS arrow (C++)"
    fi
    if pkg-config --exists arrow-glib; then
      trace "OK  arrow-glib: $(pkg-config --modversion arrow-glib)"
    else
      trace "MISS arrow-glib (Stage B GLib — required for red-arrow)"
    fi
  fi

  section "Ruby red-arrow gem"
  if have mise; then
    mise x ruby -- gem list -e red-arrow 2>/dev/null | tee -a "${REPORT}" || trace "red-arrow: not installed"
  elif have gem; then
    gem list -e red-arrow 2>/dev/null | tee -a "${REPORT}" || trace "red-arrow: not installed"
  fi

  section "R package arrow"
  if have Rscript; then
    Rscript -e 'if (requireNamespace("arrow", quietly=TRUE)) cat("OK  R arrow", as.character(packageVersion("arrow")), "\n") else cat("MISS R arrow\n")' 2>&1 | tee -a "${REPORT}"
  fi

  section "galaaz profile markers"
  ls -la "${HOME}/.config/galaaz/profiles/" 2>/dev/null | tee -a "${REPORT}" || trace "no profiles dir"
  if [[ -f "${HOME}/.config/galaaz/profiles/arrow" ]]; then
    trace "NOTE: profiles/arrow exists → Omarchy menu Arrow row is DISABLED"
    trace "      If Stage B is incomplete, remove it to re-enable the menu:"
    trace "      rm ~/.config/galaaz/profiles/arrow"
  fi

  section "prior build / install logs"
  for f in "${BUILD_LOG}" "${TRACE}" "${REPORT}"; do
    if [[ -f "${f}" ]]; then
      trace "file ${f} ($(wc -c <"${f}") bytes, mtime $(date -r "${f}" -Iseconds 2>/dev/null || true))"
    fi
  done

  section "verdict"
  local a=0 g=0 r=0 ra=0
  pkg-config --exists arrow 2>/dev/null && a=1
  pkg-config --exists arrow-glib 2>/dev/null && g=1
  if have Rscript; then
    Rscript -e 'quit(status=if (requireNamespace("arrow", quietly=TRUE)) 0 else 1)' 2>/dev/null && r=1 || true
  fi
  if have mise; then
    mise x ruby -- ruby -e 'gem "red-arrow"; puts' 2>/dev/null && ra=1 || true
  elif have ruby; then
    ruby -e 'gem "red-arrow"; puts' 2>/dev/null && ra=1 || true
  fi
  trace "Stage A (R arrow):     $([[ ${r} -eq 1 ]] && echo OK || echo MISSING)"
  trace "Arrow C++ (pkg-config): $([[ ${a} -eq 1 ]] && echo OK || echo MISSING)"
  trace "Arrow GLib:            $([[ ${g} -eq 1 ]] && echo OK || echo MISSING)"
  trace "Stage B (red-arrow):   $([[ ${ra} -eq 1 ]] && echo OK || echo MISSING)"
  if [[ ${r} -eq 1 && ${g} -eq 1 && ${ra} -eq 1 ]]; then
    trace "RESULT: Arrow Stage A+B look OK"
  elif [[ ${r} -eq 1 ]]; then
    trace "RESULT: Stage A OK; Stage B incomplete — menu install still needed for GLib/red-arrow"
  else
    trace "RESULT: Arrow not fully installed"
  fi
  trace "Full report: ${REPORT}"
}

run_last_log() {
  section "arrow-glib-build.log (last 80 lines)"
  if [[ -f "${BUILD_LOG}" ]]; then
    tail -n 80 "${BUILD_LOG}" | tee -a "${REPORT}"
  else
    trace "no ${BUILD_LOG}"
  fi
  section "arrow-install-trace.log (last 80 lines)"
  if [[ -f "${TRACE}" ]]; then
    tail -n 80 "${TRACE}" | tee -a "${REPORT}"
  else
    trace "no ${TRACE}"
  fi
  section "kernel OOM / kill hints"
  dmesg -T 2>/dev/null | grep -iE 'oom|killed process|out of memory' | tail -20 | tee -a "${REPORT}" \
    || journalctl -k -b --no-pager 2>/dev/null | grep -iE 'oom|killed process|out of memory' | tail -20 | tee -a "${REPORT}" \
    || trace "(no dmesg/journal access)"
  trace "Done. Report: ${REPORT}"
}

run_install() {
  section "traced install via omarchy-galaaz-add arrow"
  trace "If the terminal dies, re-open a terminal and run:"
  trace "  omarchy-galaaz-arrow-debug last-log"
  trace "  omarchy-galaaz-arrow-debug status"
  local add="${HOME}/.local/bin/omarchy-galaaz-add"
  if [[ ! -x "${add}" ]]; then
    add="$(command -v omarchy-galaaz-add || true)"
  fi
  if [[ -z "${add}" || ! -x "${add}" ]]; then
    trace "ERROR: omarchy-galaaz-add missing — run: galaaz omarchy install"
    return 1
  fi
  # Clear stale profile so menu/add can redo Stage B.
  if [[ -f "${HOME}/.config/galaaz/profiles/arrow" ]]; then
    trace "removing incomplete/stale profiles/arrow so install can run cleanly"
    rm -f "${HOME}/.config/galaaz/profiles/arrow"
  fi
  export GALAAZ_ARROW_TRACE=1
  export GALAAZ_ARROW_GLIB_JOBS="${GALAAZ_ARROW_GLIB_JOBS:-1}"
  trace "exec: GALAAZ_ARROW_TRACE=1 GALAAZ_ARROW_GLIB_JOBS=${GALAAZ_ARROW_GLIB_JOBS} ${add} arrow"
  sync
  "${add}" arrow
}

pause_end() {
  local st=$1
  echo
  echo "Report: ${REPORT}"
  if [[ "${st}" -ne 0 ]]; then
    echo "FAILED (exit ${st}). Press Enter to close."
  else
    echo "OK. Press Enter to close."
  fi
  read -r _ || true
  exit "${st}"
}

case "${CMD}" in
  -h|--help|help)
    sed -n '1,20p' "$0"
    exit 0
    ;;
  status|probe)
    run_status
    pause_end 0
    ;;
  last-log|logs)
    : >>"${REPORT}"
    run_last_log
    pause_end 0
    ;;
  install|add)
    run_status
    run_install
    st=$?
    run_status
    pause_end "${st}"
    ;;
  *)
    echo "Unknown command: ${CMD}"
    echo "Use: status | last-log | install"
    pause_end 1
    ;;
esac
