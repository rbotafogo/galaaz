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

pkg_add() {
  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    omarchy-pkg-add "$@"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm --needed "$@"
  else
    echo "WARN: cannot install packages ($*); install them yourself" >&2
  fi
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
    pkg_add pandoc
    if ! command -v pandoc >/dev/null 2>&1; then
      echo "ERROR: pandoc still missing after package install" >&2
      pause 1
    fi
    echo "pandoc: $(pandoc --version | head -1)"
    ;;
  tex)
    echo "==> system: pandoc (TinyTeX is installed by galaaz add tex)"
    pkg_add pandoc
    ;;
  arrow|bio|examples|ledger|demo) ;;
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

pause "${st}"
