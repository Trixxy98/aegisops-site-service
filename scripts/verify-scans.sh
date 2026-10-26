#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 3 ]; then echo 'Usage: verify-scans.sh gitleaks.sarif semgrep.sarif trivy.sarif' >&2; exit 2; fi
for scanner in gitleaks semgrep trivy; do
  file="${scanner}.sarif"
  found=false
  for arg in "$@"; do [ "$arg" != "$file" ] || found=true; done
  [ "$found" = true ] && [ -s "$file" ] || { echo "Missing $file" >&2; exit 1; }
  jq -e --arg scanner "$scanner" '
    .version == "2.1.0" and (.runs | type == "array" and length > 0) and
    all(.runs[]; (.tool.driver.name | strings | ascii_downcase | contains($scanner)) and
      (.results | type == "array"))' "$file" > /dev/null || {
    echo "Invalid or mismatched $file (no synthetic clean scan permitted)" >&2; exit 1;
  }
done
