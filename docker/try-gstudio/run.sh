#!/usr/bin/env bash
# Build and run the gstudio try image (Galaaz already installed from RubyGems).
# Usage (from repo root):
#   ./docker/try-gstudio/run.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${GALAAZ_TRY_IMAGE:-galaaz-try:gstudio}"
JRUBY_VERSION="${JRUBY_VERSION:-10.1.1.0}"
GALAAZ_VERSION="${GALAAZ_VERSION:-2.1.4}"

if ! command -v docker >/dev/null 2>&1; then
  echo "try-gstudio: docker not on PATH" >&2
  exit 1
fi

echo "[try-gstudio] docker build ${IMAGE}"
docker build \
  --build-arg "JRUBY_VERSION=${JRUBY_VERSION}" \
  --build-arg "GALAAZ_VERSION=${GALAAZ_VERSION}" \
  -t "${IMAGE}" \
  "${ROOT}/docker/try-gstudio"

echo "[try-gstudio] docker run --rm -it ${IMAGE}"
echo "Published image: docker run --rm -it ghcr.io/rbotafogo/galaaz-try:gstudio"
echo "In the shell:  vec = R.c(1, 2, 3); puts vec"
exec docker run --rm -it "${IMAGE}"
