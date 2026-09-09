#!/bin/bash
# Omarchy wrapper for `galaaz add PROFILE`.
# - Installs system deps the gem cannot (e.g. pandoc for knit)
# - Keeps the TUI open on success/failure so errors are readable
#
# Usage: omarchy-galaaz-add knit|arrow|tex|bio|examples|ledger|demo
set -euo pipefail

PROFILE="${1:-}"
if [[ -z "${PROFILE}" ]]; then
  echo "Usage: omarchy-galaaz-add <profile>"
  echo "Profiles: knit arrow tex bio examples ledger demo"
  exit 1
fi

GALAAZ="${HOME}/.local/bin/galaaz"
[[ -x "${GALAAZ}" ]] || GALAAZ="galaaz"

# Prefer user-local bin (installer / static pandoc land here).
export PATH="${HOME}/.local/bin:${PATH}"

# Official static release — avoid Arch extra/pandoc|pandoc-cli (pulls ~200 Haskell pkgs
# and often fails on TryOmarchy nested VMs).
# Default: latest GitHub release. Pin with PANDOC_RELEASE_VER=3.6.4 if needed.
latest_pandoc_ver() {
  if [[ -n "${PANDOC_RELEASE_VER:-}" ]]; then
    echo "${PANDOC_RELEASE_VER}"
    return 0
  fi
  local ver
  ver="$(
    curl -fsSL https://api.github.com/repos/jgm/pandoc/releases/latest \
      | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
      | head -1
  )"
  if [[ -z "${ver}" ]]; then
    echo "ERROR: could not resolve latest pandoc release from GitHub API" >&2
    return 1
  fi
  echo "${ver}"
}

# Install pandoc without Arch's Haskell stack. Order:
# 1) already on PATH  2) AUR pandoc-bin  3) GitHub linux tarball → ~/.local/bin
ensure_pandoc() {
  if command -v pandoc >/dev/null 2>&1; then
    echo "pandoc: $(pandoc --version | head -1) (already installed)"
    return 0
  fi

  echo "==> pandoc missing — installing (not Arch pandoc / pandoc-cli)"

  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    echo "==> try: omarchy-pkg-add pandoc-bin"
    if omarchy-pkg-add pandoc-bin && command -v pandoc >/dev/null 2>&1; then
      echo "pandoc: $(pandoc --version | head -1) (pandoc-bin)"
      return 0
    fi
    echo "WARN: pandoc-bin via omarchy-pkg-add failed; trying GitHub binary" >&2
  elif command -v yay >/dev/null 2>&1; then
    echo "==> try: yay -S pandoc-bin"
    if yay -S --noconfirm --needed pandoc-bin && command -v pandoc >/dev/null 2>&1; then
      echo "pandoc: $(pandoc --version | head -1) (pandoc-bin)"
      return 0
    fi
    echo "WARN: yay pandoc-bin failed; trying GitHub binary" >&2
  fi

  local arch asset url tmp ver
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      echo "ERROR: unsupported arch $(uname -m) for pandoc binary; install pandoc yourself" >&2
      return 1
      ;;
  esac

  if ! ver="$(latest_pandoc_ver)"; then
    return 1
  fi
  echo "==> pandoc release: ${ver}"

  asset="pandoc-${ver}-linux-${arch}.tar.gz"
  url="https://github.com/jgm/pandoc/releases/download/${ver}/${asset}"
  tmp="$(mktemp -d)"
  echo "==> download: ${url}"
  if ! curl -fsSL -o "${tmp}/${asset}" "${url}"; then
    echo "ERROR: failed to download pandoc ${ver}" >&2
    rm -rf "${tmp}"
    return 1
  fi
  tar -xzf "${tmp}/${asset}" -C "${tmp}"
  mkdir -p "${HOME}/.local/bin"
  if ! cp "${tmp}/pandoc-${ver}/bin/pandoc" "${HOME}/.local/bin/pandoc"; then
    echo "ERROR: pandoc binary missing from tarball" >&2
    rm -rf "${tmp}"
    return 1
  fi
  chmod +x "${HOME}/.local/bin/pandoc"
  rm -rf "${tmp}"

  if ! command -v pandoc >/dev/null 2>&1; then
    echo "ERROR: pandoc still not on PATH after install to ~/.local/bin" >&2
    return 1
  fi
  echo "pandoc: $(pandoc --version | head -1) (~/.local/bin, static)"
  return 0
}

pkg_add() {
  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    omarchy-pkg-add "$@"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm --needed "$@"
  else
    echo "ERROR: need omarchy-pkg-add or pacman to install: $*" >&2
    return 1
  fi
}

# Stale pacman DBs request old pkg builds that mirrors already deleted (HTTP 404).
# Sync once, then install. Prefer this for heavy deps like arrow.
pkg_add_synced() {
  if pkg_add "$@"; then
    return 0
  fi
  echo "WARN: install failed for: $* — refreshing pacman DBs and retrying (common with mirror 404s)" >&2
  if ! command -v pacman >/dev/null 2>&1; then
    return 1
  fi
  if ! sudo pacman -Sy --noconfirm; then
    echo "ERROR: pacman -Sy failed. On Omarchy run Update → Omarchy, then retry." >&2
    return 1
  fi
  # Bypass omarchy-pkg-add here so we use the freshly synced DB.
  if ! sudo pacman -S --noconfirm --needed "$@"; then
    echo "ERROR: still failed to install: $*" >&2
    echo "  On Omarchy: Super+Space → Update → Omarchy, then re-run this add-on." >&2
    return 1
  fi
  return 0
}

# red-arrow (Stage B) needs pkg-config "arrow" + "arrow-glib" at the same version.
# Arch ships C++ Arrow (extra/arrow) but not Arrow GLib — build GLib from the
# matching Apache tarball. Keep ARROW_USE_PKG_CONFIG=false for CRAN R arrow
# (LIBARROW_BINARY); pacman arrow is only for the Ruby gem.
#
# Small Omarchy/TryOmarchy VMs OOM and kill the TUI during unlimited ninja builds.
# We: default -j1, optional build swap, compile in a systemd user scope, heartbeat.
ensure_arrow_for_red_arrow() {
  local major ver tmp tarball url build_dir jobs cache log swapfile avail_mb swap_mb
  local compile_st=0
  major=25
  jobs="${GALAAZ_ARROW_GLIB_JOBS:-1}"
  cache="${HOME}/.cache/galaaz"
  log="${HOME}/.local/share/galaaz/arrow-glib-build.log"
  swapfile="${cache}/arrow-glib.swap"
  mkdir -p "${cache}" "$(dirname "${log}")"

  echo "==> system: Apache Arrow C++ + GLib (Stage B / red-arrow)"
  echo "    build log: ${log}"
  export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"

  if ! command -v pkg-config >/dev/null 2>&1; then
    pkg_add_synced pkgconf || return 1
  fi

  if ! pkg-config --exists "arrow >= ${major}" 2>/dev/null; then
    echo "==> install Arch package: arrow"
    if ! pkg_add_synced arrow; then
      echo "ERROR: failed to install Arch arrow (Apache Arrow C++)" >&2
      return 1
    fi
  fi

  if ! pkg-config --exists "arrow >= ${major}" 2>/dev/null; then
    echo "ERROR: Apache Arrow C++ >= ${major} still missing after pacman install" >&2
    echo "  pkg-config --modversion arrow: $(pkg-config --modversion arrow 2>/dev/null || echo none)" >&2
    return 1
  fi
  ver="$(pkg-config --modversion arrow)"
  echo "arrow (C++): ${ver}"

  if pkg-config --exists "arrow-glib = ${ver}" 2>/dev/null; then
    echo "arrow-glib: $(pkg-config --modversion arrow-glib) (already installed)"
    return 0
  fi

  echo "==> Arrow GLib ${ver} missing — building from Apache source (required for Stage B)"
  echo "    ninja jobs: ${jobs} (override with GALAAZ_ARROW_GLIB_JOBS)"
  # glib2-devel provides glib-mkenums (split from glib2 on Arch); without it meson fails.
  pkg_add_synced meson ninja gobject-introspection glib2 glib2-devel cmake || return 1

  avail_mb="$(awk '/MemAvailable:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  swap_mb="$(awk '/SwapFree:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
  echo "    memory: MemAvailable=${avail_mb}MiB SwapFree=${swap_mb}MiB"
  if (( avail_mb + swap_mb < 3500 )); then
    echo "==> low RAM — enabling 4GiB build swap at ${swapfile}"
    if [[ ! -f "${swapfile}" ]]; then
      if ! dd if=/dev/zero of="${swapfile}" bs=1M count=4096 status=none; then
        echo "ERROR: could not create build swap file (need ~4GiB free disk)" >&2
        return 1
      fi
      chmod 600 "${swapfile}"
      mkswap "${swapfile}" >/dev/null
    fi
    if ! sudo swapon "${swapfile}"; then
      echo "ERROR: swapon ${swapfile} failed" >&2
      return 1
    fi
  fi

  tarball="apache-arrow-${ver}.tar.gz"
  url="https://dlcdn.apache.org/arrow/arrow-${ver}/${tarball}"
  # Prefer ~/.cache over /tmp — /tmp is often tmpfs and competes with the compile for RAM.
  tmp="${cache}/arrow-${ver}-src"
  rm -rf "${tmp}"
  mkdir -p "${tmp}"
  build_dir="${tmp}/apache-arrow-${ver}"
  : >"${log}"
  echo "==> download: ${url}"
  if ! curl -fsSL -o "${tmp}/${tarball}" "${url}"; then
    url="https://archive.apache.org/dist/arrow/arrow-${ver}/${tarball}"
    echo "==> fallback: ${url}"
    if ! curl -fsSL -o "${tmp}/${tarball}" "${url}"; then
      echo "ERROR: failed to download Apache Arrow ${ver} sources" >&2
      sudo swapoff "${swapfile}" 2>/dev/null || true
      rm -rf "${tmp}"
      return 1
    fi
  fi
  if ! tar -xzf "${tmp}/${tarball}" -C "${tmp}"; then
    echo "ERROR: failed to extract ${tarball}" >&2
    sudo swapoff "${swapfile}" 2>/dev/null || true
    rm -rf "${tmp}"
    return 1
  fi
  if [[ ! -d "${build_dir}/c_glib" ]]; then
    echo "ERROR: c_glib missing from ${tarball}" >&2
    sudo swapoff "${swapfile}" 2>/dev/null || true
    rm -rf "${tmp}"
    return 1
  fi

  echo "==> meson setup arrow-glib ${ver}"
  if ! meson setup "${build_dir}/c_glib.build" "${build_dir}/c_glib" \
      --buildtype=release \
      --prefix=/usr/local \
      -Dgtk_doc=false \
      -Ddoc=false \
      -Dvapi=false >>"${log}" 2>&1; then
    echo "ERROR: meson setup for arrow-glib failed" >&2
    tail -n 40 "${log}" || true
    sudo swapoff "${swapfile}" 2>/dev/null || true
    rm -rf "${tmp}"
    return 1
  fi

  echo "==> meson compile arrow-glib ${ver} (-j${jobs}) — can take several minutes"
  echo "    leave this window open; progress also in ${log}"
  # Isolate from the TUI cgroup when possible so an OOM kills the build, not the terminal.
  set +e
  if command -v systemd-run >/dev/null 2>&1; then
    systemd-run --user --scope --quiet \
      -p MemoryMax=8G \
      -E "PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}" \
      -E "PATH=${PATH}" \
      meson compile -C "${build_dir}/c_glib.build" -j "${jobs}" >>"${log}" 2>&1 &
  else
    meson compile -C "${build_dir}/c_glib.build" -j "${jobs}" >>"${log}" 2>&1 &
  fi
  local compile_pid=$!
  while kill -0 "${compile_pid}" 2>/dev/null; do
    echo "    … still compiling arrow-glib ($(date +%H:%M:%S))"
    sleep 20
  done
  wait "${compile_pid}"
  compile_st=$?
  set -e

  if [[ "${compile_st}" -ne 0 ]]; then
    echo "ERROR: meson compile for arrow-glib failed (exit ${compile_st}) — often OOM" >&2
    echo "  log: ${log}" >&2
    tail -n 40 "${log}" || true
    echo "  Retry with more swap free disk, close other apps, or GALAAZ_ARROW_GLIB_JOBS=1" >&2
    sudo swapoff "${swapfile}" 2>/dev/null || true
    rm -rf "${tmp}"
    return 1
  fi

  echo "==> meson install arrow-glib ${ver}"
  if ! sudo meson install -C "${build_dir}/c_glib.build" >>"${log}" 2>&1; then
    echo "ERROR: meson install for arrow-glib failed" >&2
    tail -n 40 "${log}" || true
    sudo swapoff "${swapfile}" 2>/dev/null || true
    rm -rf "${tmp}"
    return 1
  fi

  sudo ldconfig 2>/dev/null || true
  sudo swapoff "${swapfile}" 2>/dev/null || true
  rm -rf "${tmp}"

  if ! pkg-config --exists "arrow-glib = ${ver}" 2>/dev/null; then
    echo "ERROR: arrow-glib ${ver} still missing after build" >&2
    echo "  pkg-config --modversion arrow-glib: $(pkg-config --modversion arrow-glib 2>/dev/null || echo none)" >&2
    echo "  log: ${log}" >&2
    return 1
  fi
  echo "arrow-glib: $(pkg-config --modversion arrow-glib) (built from Apache ${ver})"
  return 0
}

pause() {
  local st=$1
  echo
  if [[ "${st}" -ne 0 ]]; then
    echo "FAILED (exit ${st}). Read the messages above, then press Enter to close."
  else
    echo "OK. Press Enter to close."
  fi
  read -r _ || true
  exit "${st}"
}

echo "=== galaaz add ${PROFILE} ==="
echo

case "${PROFILE}" in
  knit)
    # rmarkdown/gknit need system pandoc >= 2.8 — not shipped by CRAN packages alone.
    echo "==> system: pandoc"
    if ! ensure_pandoc; then
      pause 1
    fi
    ;;
  tex)
    echo "==> system: pandoc (TinyTeX is installed by galaaz add tex)"
    if ! ensure_pandoc; then
      pause 1
    fi
    ;;
  arrow|ledger|demo)
    # R package arrow: do NOT link pacman arrow (version skew vs CRAN) —
    # LIBARROW_BINARY uses Apache's version-matched prebuilt. pacman arrow +
    # built arrow-glib are only for CRuby red-arrow (Stage B).
    export LIBARROW_BINARY=true
    export NOT_CRAN=true
    export LIBARROW_BUILD=false
    export ARROW_USE_PKG_CONFIG=false
    echo "==> arrow env: LIBARROW_BINARY=true LIBARROW_BUILD=false ARROW_USE_PKG_CONFIG=false"
    if ! ensure_arrow_for_red_arrow; then
      pause 1
    fi
    ;;
  bio|examples) ;;
  *)
    echo "Unknown profile: ${PROFILE}" >&2
    pause 1
    ;;
esac

echo "==> ${GALAAZ} add ${PROFILE}"
set +e
if [[ "${PROFILE}" == "knit" ]]; then
  "${GALAAZ}" add knit
  st=$?
  if [[ "${st}" -eq 0 ]]; then
    echo
    echo "==> ${GALAAZ} add tex (bundled with knit in Omarchy menu)"
    "${GALAAZ}" add tex
    st=$?
  fi
else
  "${GALAAZ}" add "${PROFILE}"
  st=$?
fi
set -e

if [[ "${PROFILE}" == "knit" && "${st}" -eq 0 ]]; then
  echo
  echo "Try: gknit ~/galaaz-blogs/oh_my/oh_my.Rmd"
  echo "Or menu: Knit demo (oh_my)"
fi

if [[ "${PROFILE}" == "ledger" && "${st}" -eq 0 ]]; then
  echo
  echo "Try: cd ~/r_on_rails_ledger && bin/dev"
  echo "Then http://localhost:3000 — portfolio → Run stress test"
fi

pause "${st}"
