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
    # R package arrow: do NOT rely on pacman "arrow" for linking — Arch libarrow
    # often lags CRAN and breaks configure. galaaz add arrow sets LIBARROW_BINARY
    # (Apache version-matched prebuilt). Export here too so a stale gem still works
    # if the user only refreshed this wrapper.
    export LIBARROW_BINARY=true
    export NOT_CRAN=true
    export LIBARROW_BUILD=false
    export ARROW_USE_PKG_CONFIG=false
    echo "==> arrow env: LIBARROW_BINARY=true LIBARROW_BUILD=false ARROW_USE_PKG_CONFIG=false"
    ;;
  bio|examples) ;;
  *)
    echo "Unknown profile: ${PROFILE}" >&2
    pause 1
    ;;
esac

echo "==> ${GALAAZ} add ${PROFILE}"
set +e
"${GALAAZ}" add "${PROFILE}"
st=$?
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
