#!/bin/bash
# Safe/debug gknit for Omarchy: force HTML, log everything, keep the window open.
#
# Usage:
#   omarchy-galaaz-gknit [path/to/file.Rmd]
#   omarchy-galaaz-gknit ~/galaaz-blogs/gknit/gknit.Rmd
#
# Many shipped blogs list pdf_document before html_document in YAML. A bare
# `gknit file.Rmd` then tries PDF first (LaTeX) — that often fails hard or OOMs
# a small VM. This wrapper always requests html_document and tees a log.
set -uo pipefail

LOG_DIR="${HOME}/.local/share/galaaz"
LOG="${LOG_DIR}/gknit-debug.log"
mkdir -p "${LOG_DIR}"

RMD="${1:-${HOME}/galaaz-blogs/oh_my/oh_my.Rmd}"
if [[ ! -f "${RMD}" ]]; then
  echo "Missing Rmd: ${RMD}"
  echo "Press Enter to close..."
  read -r _ || true
  exit 1
fi

{
  echo "=== gknit debug $(date -Iseconds) ==="
  echo "rmd: ${RMD}"
  echo "cwd: $(pwd)"
  echo "forcing: --output_format html_document"
  echo "log: ${LOG}"
  command -v pandoc >/dev/null && pandoc --version | head -1 || echo "pandoc: MISSING"
  command -v gknit >/dev/null && echo "gknit: $(command -v gknit)" || echo "gknit: via mise/wrapper"
  free -h 2>/dev/null | head -2 || true
  echo
} | tee "${LOG}"

# Prefer HTML explicitly — do not let YAML's pdf_document win.
set +e
(
  cd "$(dirname "${RMD}")" || exit 1
  base="$(basename "${RMD}")"
  if command -v mise >/dev/null 2>&1; then
    mise x ruby -- gknit --output_format html_document --no_clean "${base}"
  else
    gknit --output_format html_document --no_clean "${base}"
  fi
) 2>&1 | tee -a "${LOG}"
st=${PIPESTATUS[0]}
set -e

{
  echo
  echo "exit: ${st}"
  echo "--- recent kernel/OOM hints (if any) ---"
  dmesg -T 2>/dev/null | grep -iE 'oom|killed process|out of memory' | tail -5 || echo "(no dmesg access or no OOM lines)"
  html="${RMD%.Rmd}.html"
  if [[ -f "${html}" ]]; then
    echo "html: ${html}"
  else
    echo "html: not found (knit likely failed before write)"
  fi
  echo "FULL LOG: ${LOG}"
} | tee -a "${LOG}"

echo
if [[ "${st}" -ne 0 ]]; then
  echo "FAILED (exit ${st}). Scroll up or: less ${LOG}"
else
  echo "OK."
fi
echo "Press Enter to close (so a crash mid-run still leaves this log on disk)..."
read -r _ || true
exit "${st}"
