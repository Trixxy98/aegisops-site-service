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

# A manual rerun of an old commit must not re-register a different image under its version.
if grep -q 'workflow_dispatch:' "$root/.github/workflows/ci.yml"; then
  echo 'Manual rebuild is unsafe for previously registered versions' >&2; exit 1
fi
grep -q 'run: bash scripts/image-meta.sh' "$root/.github/workflows/ci.yml"
for attempt in 1 2; do
  GITHUB_REF=refs/heads/main GITHUB_REF_NAME=main GITHUB_RUN_ID=123 \
    GITHUB_RUN_ATTEMPT="$attempt" GITHUB_REPOSITORY_OWNER=Example GITHUB_OUTPUT="$tmp/output-$attempt" \
    bash "$root/scripts/image-meta.sh"
done
grep -q '^version=v0.0.0-main\..*-run.123.1$' "$tmp/output-1"
grep -q '^version=v0.0.0-main\..*-run.123.2$' "$tmp/output-2"
if cmp -s "$tmp/output-1" "$tmp/output-2"; then echo 'Rerun reused image tag' >&2; exit 1; fi
GITHUB_REF=refs/tags/v1.2.3 GITHUB_REF_NAME=v1.2.3 GITHUB_RUN_ID=456 \
  GITHUB_RUN_ATTEMPT=1 GITHUB_REPOSITORY_OWNER=Example GITHUB_OUTPUT="$tmp/tag" \
  bash "$root/scripts/image-meta.sh"
grep -q '^version=v1.2.3-run.456.1$' "$tmp/tag"
grep -q '^image=ghcr.io/example/site-service:v1.2.3-run.456.1$' "$tmp/tag"
echo 'PASS: image versions unique per attempt; no manual rebuild trigger'
