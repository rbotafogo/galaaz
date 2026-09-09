#!/bin/bash
# Safe/debug gknit for Omarchy: log everything, keep the window open.
#
# Usage:
#   omarchy-galaaz-gknit [path/to/file.Rmd ...]
#   omarchy-galaaz-gknit --output_format pdf_document path.Rmd
#   omarchy-galaaz-gknit path.Rmd pdf_document   # positional format (Nautilus)
#
# Default format is html_document. Many shipped blogs list pdf_document before
# html_document in YAML; a bare `gknit file.Rmd` then tries PDF first.
set -uo pipefail

LOG_DIR="${HOME}/.local/share/galaaz"
LOG="${LOG_DIR}/gknit-debug.log"
mkdir -p "${LOG_DIR}"

FMT="html_document"
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output_format|-o)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1"
        echo "Press Enter to close..."
        read -r _ || true
        exit 1
      fi
      FMT="$2"
      shift 2
      ;;
    --)
      shift
      FILES+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1"
      echo "Press Enter to close..."
      read -r _ || true
      exit 1
      ;;
    *)
      # Positional: first non-option that is not an existing .Rmd and looks like
      # an rmarkdown format name can be treated as format when FILES already set,
      # or as format when it does not end in .Rmd/.Rmarkdown.
      lower="${1,,}"
      if [[ "${lower}" == *.rmd || "${lower}" == *.rmarkdown ]]; then
        FILES+=("$1")
      elif [[ ${#FILES[@]} -eq 0 && -f "$1" ]]; then
        FILES+=("$1")
      elif [[ "$1" =~ ^(html_document|pdf_document|all|[a-zA-Z0-9_]+)$ ]]; then
        FMT="$1"
      else
        FILES+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ ${#FILES[@]} -eq 0 ]]; then
  FILES=("${HOME}/galaaz-blogs/oh_my/oh_my.Rmd")
fi

overall=0
for RMD in "${FILES[@]}"; do
  if [[ ! -f "${RMD}" ]]; then
    echo "Missing Rmd: ${RMD}"
    overall=1
    continue
  fi

  {
    echo "=== gknit debug $(date -Iseconds) ==="
    echo "rmd: ${RMD}"
    echo "cwd: $(pwd)"
    echo "forcing: --output_format ${FMT}"
    echo "log: ${LOG}"
    command -v pandoc >/dev/null && pandoc --version | head -1 || echo "pandoc: MISSING"
    command -v gknit >/dev/null && echo "gknit: $(command -v gknit)" || echo "gknit: via mise/wrapper"
    free -h 2>/dev/null | head -2 || true
    echo
  } | tee -a "${LOG}"

  set +e
  (
    cd "$(dirname "${RMD}")" || exit 1
    base="$(basename "${RMD}")"
    if command -v mise >/dev/null 2>&1; then
      mise x ruby -- gknit --output_format "${FMT}" --no_clean "${base}"
    else
      gknit --output_format "${FMT}" --no_clean "${base}"
    fi
  ) 2>&1 | tee -a "${LOG}"
  st=${PIPESTATUS[0]}
  set +e

  {
    echo
    echo "exit: ${st}"
    echo "--- recent kernel/OOM hints (if any) ---"
    dmesg -T 2>/dev/null | grep -iE 'oom|killed process|out of memory' | tail -5 || echo "(no dmesg access or no OOM lines)"
    stem="${RMD%.*}"
    case "${FMT}" in
      pdf_document) out="${stem}.pdf" ;;
      html_document|*) out="${stem}.html" ;;
    esac
    if [[ -f "${out}" ]]; then
      echo "output: ${out}"
    else
      echo "output: not found for format ${FMT} (knit likely failed before write)"
    fi
    echo "FULL LOG: ${LOG}"
  } | tee -a "${LOG}"

  if [[ "${st}" -ne 0 ]]; then
    overall="${st}"
  fi
done

echo
if [[ "${overall}" -ne 0 ]]; then
  echo "FAILED (exit ${overall}). Scroll up or: less ${LOG}"
else
  echo "OK."
fi
echo "Press Enter to close (so a crash mid-run still leaves this log on disk)..."
read -r _ || true
exit "${overall}"
