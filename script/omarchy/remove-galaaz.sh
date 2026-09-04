#!/bin/bash
# Remove Galaaz core gem + blogs we created. Leaves Ruby, R, and add-on R packages.
set -euo pipefail

echo -e "Removing Galaaz...\n"

run_ruby() {
  if command -v mise >/dev/null 2>&1; then
    mise x ruby -- "$@"
  else
    "$@"
  fi
}

if command -v gem >/dev/null 2>&1 || command -v mise >/dev/null 2>&1; then
  run_ruby gem uninstall galaaz -x -a --ignore-dependencies 2>/dev/null || true
fi

blogs="${HOME}/galaaz-blogs"
if [[ -f "${blogs}/.galaaz-blogs" ]]; then
  echo "Removing ${blogs} (galaaz blogs marker present)"
  rm -rf "${blogs}"
else
  echo "Leaving ${blogs} untouched (no .galaaz-blogs marker)"
fi

# Profile markers only — do not uninstall CRAN/Bioconductor/TinyTeX.
if [[ -d "${HOME}/.config/galaaz/profiles" ]]; then
  rm -rf "${HOME}/.config/galaaz/profiles"
  echo "Cleared ~/.config/galaaz/profiles"
fi

echo -e "\nNote: GNU R and language packages (arrow, knitr, …) were left installed."
echo "Done!"
