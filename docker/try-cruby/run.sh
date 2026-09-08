#!/usr/bin/env bash
# Build and run the CRuby try image (Galaaz already installed from RubyGems).
# Usage (from repo root):
#   ./docker/try-cruby/run.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${GALAAZ_TRY_CRUBY_IMAGE:-galaaz-try:cruby}"
RUBY_VERSION="${RUBY_VERSION:-3.3.12}"
GALAAZ_VERSION="${GALAAZ_VERSION:-2.1.6}"

if ! command -v docker >/dev/null 2>&1; then
  echo "try-cruby: docker not on PATH" >&2
  exit 1
fi

echo "[try-cruby] docker build ${IMAGE}"
docker build \
  --build-arg "RUBY_VERSION=${RUBY_VERSION}" \
  --build-arg "GALAAZ_VERSION=${GALAAZ_VERSION}" \
  -t "${IMAGE}" \
  "${ROOT}/docker/try-cruby"

echo "[try-cruby] docker run --rm -it ${IMAGE}"
echo "Published image: docker run --rm -it ghcr.io/rbotafogo/galaaz-try:cruby"
echo "In the shell:  vec = R.c(1, 2, 3); puts vec"
exec docker run --rm -it "${IMAGE}"
