#!/usr/bin/env bash
# Inside the Ubuntu image: install galaaz, build the gatekeeper, run smoke.rb.
# Source is a mounted /dist/*.gem, or RubyGems when GALAAZ_COLD_INSTALL_SOURCE=rubygems.
set -euo pipefail

export GEM_HOME="${GEM_HOME:-/opt/smoke-gems}"
export GEM_PATH="${GEM_HOME}"
export PATH="${GEM_HOME}/bin:/opt/jruby/bin:${PATH}"
export GALAAZ_RCPP_CACHE_DIR="${GALAAZ_RCPP_CACHE_DIR:-/tmp/galaaz_rcpp_cache_smoke}"
rm -rf "${GALAAZ_RCPP_CACHE_DIR}"
mkdir -p "${GALAAZ_RCPP_CACHE_DIR}" "${GEM_HOME}"

echo "[cold-install] ruby=$(jruby -v)"
echo "[cold-install] R=$(R --version | head -n 1)"
gem sources --add https://rubygems.org/ >/dev/null 2>&1 || true

SOURCE="${GALAAZ_COLD_INSTALL_SOURCE:-local}"
if [[ "${SOURCE}" == "rubygems" ]]; then
  echo "[cold-install] gem install galaaz from rubygems.org"
  gem install --source https://rubygems.org galaaz
else
  gem_file="$(ls -1 /dist/galaaz-*.gem 2>/dev/null | head -n 1 || true)"
  if [[ -z "${gem_file}" ]]; then
    echo "cold-install: mount the built gem at /dist/galaaz-*.gem" >&2
    exit 1
  fi
  echo "[cold-install] gem install ${gem_file} (msgpack from rubygems.org)"
  # Not --local: the .gem is a file, but runtime deps (msgpack) still come from Rubygems.
  gem install --source https://rubygems.org "${gem_file}"
fi

gem_dir="$(jruby -e "puts Gem::Specification.find_by_name('galaaz').full_gem_path")"
ver="$(jruby -e "puts Gem::Specification.find_by_name('galaaz').version")"
echo "[cold-install] galaaz ${ver} gem dir=${gem_dir}"
echo "[cold-install] make -C ext/new_bridge all"
make -C "${gem_dir}/ext/new_bridge" all

echo "[cold-install] running /work/smoke.rb from empty /work"
cd /work
jruby -J--add-opens=java.base/java.nio=ALL-UNNAMED /work/smoke.rb

if [[ "${GALAAZ_COLD_INSTALL_RUN:-smoke}" != "specs" ]]; then
  exit 0
fi

echo "[cold-install] gem install rspec (dev dependency, not in the runtime gem)"
gem install --source https://rubygems.org rspec -v '~> 3.8'

echo "[cold-install] R packages used by fast specs (dplyr, knitr, rmarkdown, arrow)"
Rscript -e "pkgs <- c('dplyr', 'knitr', 'rmarkdown', 'arrow'); inst <- rownames(installed.packages()); need <- pkgs[!pkgs %in% inst]; if (length(need)) install.packages(need, repos='https://cloud.r-project.org'); stopifnot(requireNamespace('arrow', quietly=TRUE))"

echo "[cold-install] fast specs from installed gem (no repo mount, no bundle)"
export GALAAZ_BRIDGE_TIMEOUT_SEC="${GALAAZ_BRIDGE_TIMEOUT_SEC:-300}"
cd "${gem_dir}"
mapfile -t spec_files < <(find "${gem_dir}/specs" -maxdepth 1 -type f \( -name '*_spec.rb' -o -name '*.spec.rb' \) | sort)
jruby -I "${gem_dir}/lib" \
  -J--add-opens=java.base/java.nio=ALL-UNNAMED \
  -r "${gem_dir}/specs/spec_helper.rb" \
  -S rspec --format progress \
  "${spec_files[@]}" \
  "${gem_dir}/new_bridge_specs"
