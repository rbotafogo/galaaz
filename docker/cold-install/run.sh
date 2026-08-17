#!/usr/bin/env bash
# Build galaaz-*.gem on the host, then cold-install it in a throwaway Ubuntu container.
# Usage (from repo root):
#   ./docker/cold-install/run.sh          # gem install + smoke.rb
#   ./docker/cold-install/run.sh specs    # smoke, then fast specs (specs/ + new_bridge_specs/)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${GALAAZ_COLD_INSTALL_IMAGE:-galaaz-cold-install:ubuntu}"
JRUBY_VERSION="${JRUBY_VERSION:-10.1.1.0}"

if ! command -v docker >/dev/null 2>&1; then
  echo "cold-install: docker not on PATH" >&2
  exit 1
fi

cd "${ROOT}"
echo "[cold-install] gem build galaaz.gemspec"
rm -f "${ROOT}"/galaaz-*.gem
gem build galaaz.gemspec
GEM_FILE="$(ls -1 "${ROOT}"/galaaz-*.gem | head -n 1)"

echo "[cold-install] docker build ${IMAGE}"
docker build \
  --build-arg "JRUBY_VERSION=${JRUBY_VERSION}" \
  -t "${IMAGE}" \
  "${ROOT}/docker/cold-install"

DIST="$(mktemp -d)"
trap 'rm -rf "${DIST}"' EXIT
cp "${GEM_FILE}" "${DIST}/"

MODE="${1:-smoke}"
if [[ "${MODE}" != "smoke" && "${MODE}" != "specs" ]]; then
  echo "usage: $0 [smoke|specs]" >&2
  exit 1
fi
echo "[cold-install] docker run (no repo mount) mode=${MODE}"
docker run --rm \
  -e GALAAZ_RCPP_CACHE_DIR=/tmp/galaaz_rcpp_cache_smoke \
  -e "GALAAZ_COLD_INSTALL_RUN=${MODE}" \
  -v "${DIST}:/dist:ro" \
  "${IMAGE}"
