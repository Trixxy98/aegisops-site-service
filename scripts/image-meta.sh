#!/usr/bin/env bash
set -euo pipefail
# A rerun must never publish new bytes under an existing registered version.
: "${GITHUB_RUN_ID:?}" "${GITHUB_RUN_ATTEMPT:?}" "${GITHUB_OUTPUT:?}" "${GITHUB_REPOSITORY_OWNER:?}"
if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
  base="${GITHUB_REF#refs/tags/}"
else
  ref="${GITHUB_REF_NAME//\//-}"
  base="v0.0.0-${ref}.$(git -C "$(dirname "$0")/.." rev-parse --short HEAD)"
fi
version="${base}-run.${GITHUB_RUN_ID}.${GITHUB_RUN_ATTEMPT}"
owner=$(printf '%s' "$GITHUB_REPOSITORY_OWNER" | tr '[:upper:]' '[:lower:]')
image="ghcr.io/${owner}/site-service:${version}"
echo "version=${version}" >> "$GITHUB_OUTPUT"
echo "image=${image}" >> "$GITHUB_OUTPUT"
