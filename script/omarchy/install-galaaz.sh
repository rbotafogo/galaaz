#!/bin/bash
# Omarchy-shaped core installer for Galaaz (R-on-Rails).
# omarchy:summary=Configure Galaaz (R-on-Rails)
# omarchy:name=galaaz
#
# Prerequisite (do this yourself first — this script does NOT gem install):
#   gem install galaaz          # or: gem install galaaz -v x.y.z / .pre.N
#   galaaz omarchy install      # menu overlay + helpers
# Then: Super+Space → Install → Development → Galaaz → Galaaz (core)
#
# Debug log (always written, even if TUI tee fails):
#   ~/.local/share/galaaz/install-core.log
set -euo pipefail

LOG_DIR="${HOME}/.local/share/galaaz"
LOG="${LOG_DIR}/install-core.log"
mkdir -p "${LOG_DIR}"

# Plain file logging — process-substitution tee often dies under omarchy-launch-tui.
: >"${LOG}"
log() {
  # shellcheck disable=SC3037
  echo -e "$*" | tee -a "${LOG}"
}
log_cmd() {
  log "+ $*"
  # Capture status without aborting set -e mid-pipeline awkwardly
  set +e
  "$@" >>"${LOG}" 2>&1
  local st=$?
  set -e
  if [[ ${st} -ne 0 ]]; then
    log "ERROR: command failed (exit ${st}): $*"
    log "---- last 40 log lines ----"
    tail -n 40 "${LOG}" | tee -a /dev/tty 2>/dev/null || tail -n 40 "${LOG}"
  fi
  return "${st}"
}

on_err() {
  local st=$?
  log ""
  log "FAILED (exit ${st}) at line ${BASH_LINENO[0]:-?} — see full log:"
  log "  ${LOG}"
  log "Copy out with: cat ${LOG}"
  exit "${st}"
}
trap on_err ERR

log "=== galaaz core configure $(date -Iseconds) ==="
log "log file: ${LOG}"
log "script: ${BASH_SOURCE[0]}"
log "pwd: $(pwd)"
log "user: $(id -un) home=${HOME}"
log "PATH: ${PATH}"
log "(uses already-installed galaaz gem — does not gem install)"
log ""

pkg_add() {
  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    log_cmd omarchy-pkg-add "$@"
  elif command -v pacman >/dev/null 2>&1; then
    log_cmd sudo pacman -S --noconfirm --needed "$@"
  else
    log "WARN: skipping Arch packages ($*); install GNU R + build tools yourself"
  fi
}

log "==> packages"
pkg_add r make gcc gcc-libs libyaml pkgconf

if ! command -v ruby >/dev/null 2>&1; then
  if command -v mise >/dev/null 2>&1; then
    mise settings add ruby.compile false 2>/dev/null || true
    mise settings add idiomatic_version_file_enable_tools ruby 2>/dev/null || true
    log_cmd mise use --global ruby@latest
  else
    log "ERROR: ruby not found and mise missing"
    exit 1
  fi
fi

if command -v mise >/dev/null 2>&1; then
  if ! mise x ruby -- ruby -e 'exit(RUBY_ENGINE == "ruby" ? 0 : 1)' 2>/dev/null; then
    log "Active Ruby is not CRuby; installing MRI via mise..."
    mise use --global ruby@3.4 2>/dev/null || mise use --global ruby@latest
  fi
  if ! mise x ruby -- ruby -e 'exit(RUBY_ENGINE == "ruby" ? 0 : 1)'; then
    log "ERROR: need CRuby (MRI) for the gatekeeper .so"
    mise x ruby -- ruby -v >>"${LOG}" 2>&1 || true
    exit 1
  fi
fi

if ! command -v R >/dev/null 2>&1 || ! command -v Rscript >/dev/null 2>&1; then
  log "ERROR: R/Rscript missing after package install"
  log "which R: $(command -v R || echo none) Rscript: $(command -v Rscript || echo none)"
  exit 1
fi

log "R: $(R --version 2>/dev/null | head -1)"
log "RHOME: $(R RHOME 2>/dev/null || echo '?')"
log "ruby: $(mise x ruby -- ruby -v 2>/dev/null || ruby -v)"
log "engine: $(mise x ruby -- ruby -e 'print RUBY_ENGINE' 2>/dev/null || ruby -e 'print RUBY_ENGINE')"

# Arch/Omarchy: system R library (/usr/lib/R/library) is root-only.
# Without a user lib, install.packages("Rcpp") fails with "lib is not writable".
ensure_user_r_lib() {
  export R_LIBS_USER="${R_LIBS_USER:-${HOME}/.local/lib/R/library}"
  mkdir -p "${R_LIBS_USER}"
  local renviron="${HOME}/.Renviron"
  if [[ ! -f "${renviron}" ]] || ! grep -q '^R_LIBS_USER=' "${renviron}" 2>/dev/null; then
    echo "R_LIBS_USER=${R_LIBS_USER}" >>"${renviron}"
  fi
  log "R_LIBS_USER=${R_LIBS_USER}"
  log "Renviron: ${renviron}"
}
ensure_user_r_lib

{
  echo "---- R CMD config ----"
  R CMD config CXX || true
  R CMD config CXXFLAGS || true
  R CMD config --cppflags || true
  R CMD config --ldflags || true
  echo "---- which ----"
  command -v make; command -v gcc; command -v g++; command -v mise || true
  command -v ruby; command -v gem || true
  mise ls 2>/dev/null || true
  echo "---- .libPaths ----"
  Rscript -e '.libPaths()' || true
} >>"${LOG}" 2>&1

echo "gem: --no-document" >"${HOME}/.gemrc"

run_ruby() {
  if command -v mise >/dev/null 2>&1; then
    mise x ruby -- "$@"
  else
    "$@"
  fi
}

gem_root() {
  run_ruby ruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path"
}

gatekeeper_path() {
  run_ruby ruby -e "puts File.join(Gem::Specification.find_by_name('galaaz').full_gem_path, 'ext', 'new_bridge', 'galaaz_gatekeeper.so')"
}

# Invoke gem CLI without `ruby -S galaaz` (that finds ~/.local/bin/galaaz wrapper).
galaaz_cli() {
  run_ruby ruby -e 'load Gem.activate_bin_path("galaaz", "galaaz")' -- "$@"
}

install_wrapper() {
  mkdir -p "${HOME}/.local/bin"
  cat >"${HOME}/.local/bin/galaaz" <<'WRAP'
#!/bin/bash
set -euo pipefail
# Do not use `ruby -S galaaz`: PATH often includes this wrapper → LoadError.
if command -v mise >/dev/null 2>&1; then
  exec mise x ruby -- ruby -e 'load Gem.activate_bin_path("galaaz", "galaaz")' -- "$@"
fi
exec ruby -e 'load Gem.activate_bin_path("galaaz", "galaaz")' -- "$@"
WRAP
  chmod +x "${HOME}/.local/bin/galaaz"
  log "wrapper: ${HOME}/.local/bin/galaaz"
}

# Gem must already be installed (user: gem install galaaz [ -v … ]).
# Do NOT gem install/uninstall here — that pulled stable latest over prereleases.
log "==> require installed galaaz gem"
if ! ROOT="$(gem_root 2>/dev/null)" || [[ -z "${ROOT}" || ! -d "${ROOT}" ]]; then
  log "ERROR: galaaz gem not found under this Ruby."
  log "Install first, then re-run core configure:"
  log "  gem install galaaz    # or gem install galaaz -v <version>"
  log "  galaaz omarchy install"
  exit 1
fi
INSTALLED="$(run_ruby ruby -e "puts Gem::Specification.find_by_name('galaaz').version")"
log "using galaaz ${INSTALLED}"
log "gem root: ${ROOT}"

BRIDGE="${ROOT}/ext/new_bridge"
log "bridge: ${BRIDGE}"
ls -la "${BRIDGE}" >>"${LOG}" 2>&1 || true
if [[ ! -f "${BRIDGE}/Makefile" ]]; then
  log "ERROR: bridge Makefile missing: ${BRIDGE}/Makefile"
  exit 1
fi

log "==> ensure Rcpp (CRAN, user library)"
log_cmd Rscript -e "
  lib <- Sys.getenv('R_LIBS_USER')
  if (!nzchar(lib)) lib <- file.path(Sys.getenv('HOME'), '.local', 'lib', 'R', 'library')
  dir.create(lib, recursive=TRUE, showWarnings=FALSE)
  .libPaths(c(lib, .libPaths()))
  if (!requireNamespace('Rcpp', quietly=TRUE))
    install.packages('Rcpp', lib=lib, repos='https://cloud.r-project.org')
  cat('Rcpp=', requireNamespace('Rcpp', quietly=TRUE), ' lib=', lib, '\n', sep='')
  if (!requireNamespace('Rcpp', quietly=TRUE)) quit(status=1)
"

log "==> build gatekeeper (make -C ext/new_bridge)"
rm -f "${BRIDGE}/galaaz_gatekeeper.so" "${BRIDGE}"/*.o

# Older gems hardcoded -L$(R_HOME)/lib -lR which fails on Arch (RHOME=/usr/lib64/R).
# 2.1.2+ ships a fixed Makefile; still override LDFLAGS for safety.
R_LDFLAGS="$(R CMD config --ldflags)"
log "R CMD config --ldflags: ${R_LDFLAGS}"
log "Rcpp include: $(Rscript -e "cat(system.file('include', package='Rcpp'))")"
if grep -q 'LDFLAGS := -L\$(R_HOME)/lib -lR' "${BRIDGE}/Makefile" 2>/dev/null; then
  log "patching gem Makefile LDFLAGS for Arch/Omarchy"
  sed -i 's|^LDFLAGS := -L\$(R_HOME)/lib -lR.*|LDFLAGS := \$(shell R CMD config --ldflags) -Wl,-rpath,\$(R_HOME)/lib|' "${BRIDGE}/Makefile" || true
fi

set +e
make -C "${BRIDGE}" all LDFLAGS="${R_LDFLAGS} -Wl,-rpath,$(R RHOME)/lib" 2>&1 | tee -a "${LOG}"
make_st=${PIPESTATUS[0]}
set -e
if [[ ${make_st} -ne 0 ]]; then
  log "ERROR: make failed (exit ${make_st}) — retry verbose"
  make -C "${BRIDGE}" all LDFLAGS="${R_LDFLAGS} -Wl,-rpath,$(R RHOME)/lib" 2>&1 | tee -a "${LOG}" || true
  log "---- bridge dir ----"
  ls -la "${BRIDGE}" 2>&1 | tee -a "${LOG}" || true
  log "Full log: ${LOG}"
  exit 1
fi

SO="$(gatekeeper_path)"
log "expected so: ${SO}"
ls -la "${SO}" >>"${LOG}" 2>&1 || true
if [[ ! -f "${SO}" ]]; then
  log "ERROR: gatekeeper missing after make"
  ls -la "${BRIDGE}" 2>&1 | tee -a "${LOG}" || true
  exit 1
fi
log "gatekeeper OK: ${SO}"

log "==> galaaz setup (CLI)"
galaaz_cli setup >>"${LOG}" 2>&1 || log "WARN: galaaz setup non-zero (so exists; continuing)"

log "==> galaaz blogs init/sync"
# Fresh machine: init. Upgrade / re-run: sync brand assets without wiping blogs
# (older gems omitted _logo_before_body.html → pandoc error 99).
if [[ -f "${HOME}/galaaz-blogs/.galaaz-blogs" ]]; then
  galaaz_cli blogs sync "${HOME}/galaaz-blogs" >>"${LOG}" 2>&1 || log "WARN: blogs sync non-zero"
else
  galaaz_cli blogs init "${HOME}/galaaz-blogs" >>"${LOG}" 2>&1 || log "WARN: blogs init non-zero"
fi

install_wrapper

log "==> doctor"
export PATH="${HOME}/.local/bin:${PATH}"
hash -r 2>/dev/null || true
if ! "${HOME}/.local/bin/galaaz" doctor >>"${LOG}" 2>&1; then
  log "ERROR: doctor incomplete"
  log "so exists=$([[ -f ${SO} ]] && echo yes || echo no)"
  "${HOME}/.local/bin/galaaz" doctor 2>&1 | tee -a "${LOG}" || true
  exit 1
fi
"${HOME}/.local/bin/galaaz" doctor 2>&1 | tee -a "${LOG}" || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${HOME}/.config/omarchy/extensions" "${HOME}/.local/bin" "${HOME}/.local/share/fonts/galaaz"
if [[ -f "${SCRIPT_DIR}/omarchy-menu.jsonc" ]]; then
  cp "${SCRIPT_DIR}/omarchy-menu.jsonc" "${HOME}/.config/omarchy/extensions/omarchy-menu.jsonc"
fi
if [[ -f "${SCRIPT_DIR}/fonts/galaaz.ttf" ]]; then
  mkdir -p "${HOME}/.local/share/fonts/galaaz"
  cp "${SCRIPT_DIR}/fonts/galaaz.ttf" "${HOME}/.local/share/fonts/galaaz/galaaz.ttf"
  log "menu font (debug family galaaz): ${HOME}/.local/share/fonts/galaaz/galaaz.ttf"
fi
if [[ -f "${SCRIPT_DIR}/fonts/omarchy-with-galaaz.ttf" ]]; then
  mkdir -p "${HOME}/.local/share/fonts" "${HOME}/.config/fontconfig/conf.d"
  cp "${SCRIPT_DIR}/fonts/omarchy-with-galaaz.ttf" "${HOME}/.local/share/fonts/omarchy-with-galaaz.ttf"
  cat >"${HOME}/.config/fontconfig/conf.d/99-galaaz-omarchy-brand.conf" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- Prefer Galaaz-extended Omarchy brand font (adds U+E90E). -->
  <selectfont>
    <rejectfont>
      <glob>*/omarchy/omarchy.ttf</glob>
    </rejectfont>
  </selectfont>
</fontconfig>
XML
  log "menu font (family omarchy + U+E90E): ${HOME}/.local/share/fonts/omarchy-with-galaaz.ttf"
fi
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -r >/dev/null 2>&1 || true
  fc-cache -f "${HOME}/.local/share/fonts" >/dev/null 2>&1 || true
fi
cp "${BASH_SOURCE[0]}" "${HOME}/.local/bin/omarchy-install-galaaz"
chmod +x "${HOME}/.local/bin/omarchy-install-galaaz"
if [[ -f "${SCRIPT_DIR}/remove-galaaz.sh" ]]; then
  cp "${SCRIPT_DIR}/remove-galaaz.sh" "${HOME}/.local/bin/omarchy-remove-galaaz"
  chmod +x "${HOME}/.local/bin/omarchy-remove-galaaz"
fi
if [[ -f "${SCRIPT_DIR}/galaaz-guide.sh" ]]; then
  cp "${SCRIPT_DIR}/galaaz-guide.sh" "${HOME}/.local/bin/omarchy-galaaz-guide"
  chmod +x "${HOME}/.local/bin/omarchy-galaaz-guide"
  log "guide: ${HOME}/.local/bin/omarchy-galaaz-guide"
fi
if [[ -f "${SCRIPT_DIR}/galaaz-add.sh" ]]; then
  cp "${SCRIPT_DIR}/galaaz-add.sh" "${HOME}/.local/bin/omarchy-galaaz-add"
  chmod +x "${HOME}/.local/bin/omarchy-galaaz-add"
  log "add helper: ${HOME}/.local/bin/omarchy-galaaz-add"
fi
if [[ -f "${SCRIPT_DIR}/galaaz-gknit.sh" ]]; then
  cp "${SCRIPT_DIR}/galaaz-gknit.sh" "${HOME}/.local/bin/omarchy-galaaz-gknit"
  chmod +x "${HOME}/.local/bin/omarchy-galaaz-gknit"
  log "gknit helper: ${HOME}/.local/bin/omarchy-galaaz-gknit"
fi

# Nautilus right-click → Scripts → Galaaz → gknit
NAUTILUS_SCRIPTS_SRC="${SCRIPT_DIR}/nautilus-scripts"
NAUTILUS_SCRIPTS_DEST="${HOME}/.local/share/nautilus/scripts/Galaaz"
if [[ -d "${NAUTILUS_SCRIPTS_SRC}" ]]; then
  mkdir -p "${NAUTILUS_SCRIPTS_DEST}"
  if [[ -f "${NAUTILUS_SCRIPTS_SRC}/gknit-html" ]]; then
    cp "${NAUTILUS_SCRIPTS_SRC}/gknit-html" "${NAUTILUS_SCRIPTS_DEST}/Gknit HTML"
    chmod +x "${NAUTILUS_SCRIPTS_DEST}/Gknit HTML"
  fi
  if [[ -f "${NAUTILUS_SCRIPTS_SRC}/gknit-pdf" ]]; then
    cp "${NAUTILUS_SCRIPTS_SRC}/gknit-pdf" "${NAUTILUS_SCRIPTS_DEST}/Gknit PDF"
    chmod +x "${NAUTILUS_SCRIPTS_DEST}/Gknit PDF"
  fi
  if [[ -f "${NAUTILUS_SCRIPTS_SRC}/gknit-choose-format" ]]; then
    cp "${NAUTILUS_SCRIPTS_SRC}/gknit-choose-format" "${NAUTILUS_SCRIPTS_DEST}/Gknit Choose Format"
    chmod +x "${NAUTILUS_SCRIPTS_DEST}/Gknit Choose Format"
  fi
  log "nautilus Scripts/Galaaz: ${NAUTILUS_SCRIPTS_DEST}"
fi

mkdir -p "${HOME}/.config/galaaz/profiles"
date -Iseconds >"${HOME}/.config/galaaz/profiles/core"

log ""
log "Core configure complete."
log "Next: Super+Space → Install → Development → Galaaz → Guide (what's next)"
log "Docs: https://rbotafogo.github.io/galaaz/"
log "FULL LOG: ${LOG}"
log "Done!"
