#!/usr/bin/env bash
# Cold-install galaaz on CRuby in a throwaway Ubuntu container (no git repo inside).
# Usage (from repo root):
#   ./docker/cold-install-cruby/run.sh                 # host gem build + smoke.rb
#   ./docker/cold-install-cruby/run.sh specs           # host gem build + smoke + fast specs
#   ./docker/cold-install-cruby/run.sh published       # gem install galaaz from RubyGems + smoke
#   ./docker/cold-install-cruby/run.sh published-specs # RubyGems install + smoke + fast specs
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${GALAAZ_COLD_INSTALL_CRUBY_IMAGE:-galaaz-cold-install-cruby:ubuntu}"
RUBY_VERSION="${RUBY_VERSION:-3.3.12}"

if ! command -v docker >/dev/null 2>&1; then
  echo "cold-install-cruby: docker not on PATH" >&2
  exit 1
fi

MODE="${1:-smoke}"
SOURCE=local
RUN=smoke
case "${MODE}" in
  smoke) RUN=smoke ;;
  specs) RUN=specs ;;
  published) SOURCE=rubygems; RUN=smoke ;;
  published-specs) SOURCE=rubygems; RUN=specs ;;
  *)
    echo "usage: $0 [smoke|specs|published|published-specs]" >&2
    exit 1
    ;;
esac

cd "${ROOT}"
echo "[cold-install-cruby] docker build ${IMAGE}"
docker build \
  --build-arg "RUBY_VERSION=${RUBY_VERSION}" \
  -t "${IMAGE}" \
  "${ROOT}/docker/cold-install-cruby"

RUN_ARGS=(
  docker run --rm
  -e GALAAZ_RCPP_CACHE_DIR=/tmp/galaaz_rcpp_cache_smoke
  -e "GALAAZ_COLD_INSTALL_RUN=${RUN}"
  -e "GALAAZ_COLD_INSTALL_SOURCE=${SOURCE}"
)

if [[ "${SOURCE}" == "local" ]]; then
  echo "[cold-install-cruby] gem build galaaz.gemspec"
  rm -f "${ROOT}"/galaaz-*.gem
  # Prefer CRuby for the host gem build when available; JRuby also works.
  if command -v ruby >/dev/null 2>&1; then
    ruby -S gem build galaaz.gemspec
  else
    gem build galaaz.gemspec
  fi
  GEM_FILE="$(ls -1 "${ROOT}"/galaaz-*.gem | head -n 1)"
  DIST="$(mktemp -d)"
  trap 'rm -rf "${DIST}"' EXIT
  cp "${GEM_FILE}" "${DIST}/"
  RUN_ARGS+=(-v "${DIST}:/dist:ro")
fi

echo "[cold-install-cruby] docker run (no repo mount) source=${SOURCE} mode=${RUN}"
"${RUN_ARGS[@]}" "${IMAGE}"
