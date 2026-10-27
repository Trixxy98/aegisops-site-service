#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 2 ]; then echo 'Usage: test-summary.sh <xunit-ctrf.json> <summary.json>' >&2; exit 2; fi
jq -e '{total:.results.summary.tests, passed:.results.summary.passed,
  failed:.results.summary.failed, skipped:.results.summary.skipped,
  durationSeconds:(.results.summary.duration / 1000)} |
  select((.total | type == "number") and .total > 0 and .total == .passed + .failed + .skipped and
    .failed == 0 and .passed > 0 and (.durationSeconds | type == "number"))' "$1" > "$2"
