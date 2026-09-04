#!/bin/bash
# Collect Galaaz / Omarchy debug info into one file you can paste or copy out.
# Usage: bash debug-galaaz.sh
# Writes: ~/.local/share/galaaz/debug.log  (+ Desktop copy if Desktop exists)
set -u

LOG_DIR="${HOME}/.local/share/galaaz"
OUT="${LOG_DIR}/debug.log"
mkdir -p "${LOG_DIR}"
: >"${OUT}"

say() { echo -e "$*" | tee -a "${OUT}"; }

say "=== galaaz debug $(date -Iseconds) ==="
say "user=$(id -un) home=${HOME}"
say "PATH=${PATH}"
say ""

say "== which =="
for c in ruby gem mise R Rscript make gcc g++ galaaz omarchy-install-galaaz; do
  say "  ${c}: $(command -v "${c}" 2>/dev/null || echo MISSING)"
done

say ""
say "== versions =="
{ ruby -v; gem -v; mise -v; R --version | head -1; } >>"${OUT}" 2>&1 || true
say "RUBY_ENGINE=$(ruby -e 'print RUBY_ENGINE' 2>/dev/null || echo '?')"
if command -v mise >/dev/null 2>&1; then
  say "mise ruby -v: $(mise x ruby -- ruby -v 2>/dev/null || echo fail)"
  say "mise engine: $(mise x ruby -- ruby -e 'print RUBY_ENGINE' 2>/dev/null || echo fail)"
  mise ls >>"${OUT}" 2>&1 || true
fi

say ""
say "== gem galaaz =="
{
  gem list galaaz
  gem which galaaz 2>/dev/null || true
  ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path" 2>/dev/null || echo 'gem root: FAIL'
  if command -v mise >/dev/null 2>&1; then
    echo '--- mise x ruby ---'
    mise x ruby -- gem list galaaz
    mise x ruby -- ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path"
  fi
} >>"${OUT}" 2>&1 || true

ROOT="$(ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path" 2>/dev/null || true)"
if [[ -z "${ROOT}" ]] && command -v mise >/dev/null 2>&1; then
  ROOT="$(mise x ruby -- ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path" 2>/dev/null || true)"
fi
say "gem root: ${ROOT:-UNKNOWN}"
if [[ -n "${ROOT}" ]]; then
  BRIDGE="${ROOT}/ext/new_bridge"
  say "bridge: ${BRIDGE}"
  ls -la "${BRIDGE}" >>"${OUT}" 2>&1 || say "bridge ls FAILED"
  SO="${BRIDGE}/galaaz_gatekeeper.so"
  say "gatekeeper: ${SO} exists=$([[ -f ${SO} ]] && echo YES || echo NO)"
fi

say ""
say "== galaaz doctor =="
{
  command -v galaaz && galaaz doctor
  [[ -x "${HOME}/.local/bin/galaaz" ]] && echo '--- ~/.local/bin/galaaz ---' && "${HOME}/.local/bin/galaaz" doctor
  command -v mise && mise x ruby -- ruby -S galaaz doctor
} >>"${OUT}" 2>&1 || true

say ""
say "== profiles / blogs =="
ls -la "${HOME}/.config/galaaz/profiles" >>"${OUT}" 2>&1 || say "no profiles dir"
ls -la "${HOME}/galaaz-blogs" >>"${OUT}" 2>&1 || say "no galaaz-blogs"
say "install-core.log present=$([[ -f ${LOG_DIR}/install-core.log ]] && echo YES || echo NO)"

say ""
say "== prior install-core.log (tail 80) =="
if [[ -f "${LOG_DIR}/install-core.log" ]]; then
  tail -n 80 "${LOG_DIR}/install-core.log" | tee -a "${OUT}"
else
  say "(none yet — run omarchy-install-galaaz first)"
fi

for d in "${HOME}/Desktop" "${HOME}/desktop"; do
  if [[ -d "${d}" ]]; then
    cp "${OUT}" "${d}/galaaz-debug.log"
    say "copied to ${d}/galaaz-debug.log"
  fi
done

say ""
say "FULL DEBUG LOG: ${OUT}"
say "Paste that file contents back for diagnosis."
