#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/ctrf.json" <<'JSON'
{"results":{"summary":{"tests":2,"passed":2,"failed":0,"skipped":0,"duration":250}}}
JSON
bash "$root/scripts/test-summary.sh" "$tmp/ctrf.json" "$tmp/summary.json"
jq -e '.total == 2 and .passed == 2 and .durationSeconds == 0.25' "$tmp/summary.json" > /dev/null
echo '{"results":{"summary":{"tests":0,"passed":0,"failed":0,"skipped":0,"duration":0}}}' > "$tmp/ctrf.json"
if bash "$root/scripts/test-summary.sh" "$tmp/ctrf.json" "$tmp/summary.json" 2>/dev/null; then
  echo 'Zero discovered tests accepted' >&2; exit 1
fi

cd "$tmp"
for scanner in gitleaks semgrep trivy; do
  jq -nc --arg scanner "$scanner" '{version:"2.1.0",runs:[{tool:{driver:{name:$scanner}},results:[]}]}' > "$scanner.sarif"
done
bash "$root/scripts/verify-scans.sh" gitleaks.sarif semgrep.sarif trivy.sarif
echo '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"none"}},"results":[]}]}' > semgrep.sarif
if bash "$root/scripts/verify-scans.sh" gitleaks.sarif semgrep.sarif trivy.sarif 2>/dev/null; then
  echo 'Fake scan accepted' >&2; exit 1
fi
echo 'PASS: real test totals and scanner SARIF validation'
