#!/usr/bin/env bash
set -euo pipefail
# The marker must be an entire line of the push's head commit message, not
# a mention in a PR body, quoted instructions, or an earlier commit in a push.
if [[ "${GITHUB_EVENT_NAME:-}" != push || "${GITHUB_REF:-}" != refs/heads/demo/vulnerable ]] ||
   ! grep -Fxq '[security-denial:staging]' <<< "${MESSAGE:-}"; then
  echo 'Vulnerable demo requires a push to demo/vulnerable with a standalone [security-denial:staging] head-commit line' >&2
  exit 1
fi
