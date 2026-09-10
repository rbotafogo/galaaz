#!/bin/bash
# Omarchy helpers for Galaaz discovery (docs + example knits).
# Installed as ~/.local/bin/omarchy-galaaz-guide (and thin aliases).
set -euo pipefail

DOCS_WEB="https://rbotafogo.github.io/galaaz/"
DOCS_GH="https://github.com/rbotafogo/galaaz"
DOCS_README="https://github.com/rbotafogo/galaaz/blob/galaaz2_0/README.md"
DOCS_OMARCHY="https://github.com/rbotafogo/galaaz/blob/galaaz2_0/script/omarchy/README.md"
BLOGS="${HOME}/galaaz-blogs"
GALAAZ_BIN="${HOME}/.local/bin/galaaz"
[[ -x "${GALAAZ_BIN}" ]] || GALAAZ_BIN="galaaz"

open_url() {
  local url="$1"
  # Omarchy Learn menu uses launch-webapp; try browser helpers before xdg-open.
  if command -v omarchy-launch-webapp >/dev/null 2>&1; then
    omarchy-launch-webapp "${url}"
  elif command -v omarchy-launch-browser >/dev/null 2>&1; then
    omarchy-launch-browser "${url}"
  elif command -v omarchy-launch-web >/dev/null 2>&1; then
    omarchy-launch-web "${url}"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "${url}"
  else
    echo "Open in a browser: ${url}"
    return 1
  fi
}

cmd="${1:-tips}"
case "${cmd}" in
  tips|guide|help|"")
    cat <<EOF

Galaaz — what you can do next
=============================

Core is installed. Blog sources live in:
  ${BLOGS}

Documentation
  Website:  ${DOCS_WEB}
  GitHub:   ${DOCS_GH}
  README:   ${DOCS_README}

After: galaaz add knit   (Install → Development → Galaaz → Knit)
  Needs system pandoc (Omarchy installs it via omarchy-galaaz-add knit).
  Example knits (HTML — force html_document; bare gknit may try PDF first):
    gknit --output_format html_document ${BLOGS}/oh_my/oh_my.Rmd
    gknit --output_format html_document ${BLOGS}/gknit/gknit.Rmd
    omarchy-galaaz-gknit ${BLOGS}/gknit/gknit.Rmd   # logged, HTML-only, waits

  Or from the menu:  Knit demo (oh_my)

Other add-ons
  galaaz add arrow-r      # Arrow (R only) — CRAN arrow / Apache prebuilt
  galaaz add arrow-ruby   # Arrow (Ruby) — installs R only first, then red-arrow
  galaaz add ledger       # R-on-Rails demo app → ~/r_on_rails_ledger && bin/dev
  galaaz add examples     # Ruby examples → ~/galaaz-examples
                          #   ruby ~/galaaz-examples/misc/ggplot.rb
                          #   less ~/galaaz-examples/README.md
  galaaz add tex          # TinyTeX / PDF (large)
  galaaz add bio          # Bioconductor DESeq2 (large)

Check:  galaaz doctor
Menu:   Super+Space → Install → Development → Galaaz

Heavy CRAN installs / long R (gem 2.1.8+): R::Job keeps the bridge free.
  See README → “Background R jobs (R::Job)” (${DOCS_README})

EOF
    if [[ -d "${BLOGS}" ]]; then
      echo "Blog folders found:"
      ls -1 "${BLOGS}" 2>/dev/null | sed 's/^/  /' || true
      echo
    fi
    echo "Press Enter to close..."
    read -r _ || true
    ;;
  docs|web)
    echo "Opening ${DOCS_WEB}"
    open_url "${DOCS_WEB}"
    ;;
  github|gh)
    echo "Opening ${DOCS_GH}"
    open_url "${DOCS_GH}"
    ;;
  knit-demo|demo)
    rmd="${BLOGS}/oh_my/oh_my.Rmd"
    if [[ ! -f "${rmd}" ]]; then
      echo "Missing ${rmd}"
      echo "Run core install first (blogs init), then: galaaz add knit"
      exit 1
    fi
    if [[ ! -f "${HOME}/.config/galaaz/profiles/knit" ]]; then
      echo "Knit profile not installed yet. Run: galaaz add knit"
      exit 1
    fi
    # Prefer debug wrapper (HTML-only + log) when installed.
    if [[ -x "${HOME}/.local/bin/omarchy-galaaz-gknit" ]]; then
      exec "${HOME}/.local/bin/omarchy-galaaz-gknit" "${rmd}"
    fi
    echo "Knitting demo (HTML only): ${rmd}"
    if command -v mise >/dev/null 2>&1; then
      mise x ruby -- gknit --output_format html_document "${rmd}"
    elif command -v gknit >/dev/null 2>&1; then
      gknit --output_format html_document "${rmd}"
    else
      ruby -S gknit --output_format html_document "${rmd}"
    fi
    html="${BLOGS}/oh_my/oh_my.html"
    if [[ -f "${html}" ]]; then
      echo "Wrote ${html}"
      open_url "file://${html}"
    fi
    echo "Press Enter to close..."
    read -r _ || true
    ;;
  *)
    echo "Usage: omarchy-galaaz-guide [tips|docs|github|knit-demo]"
    exit 1
    ;;
esac
