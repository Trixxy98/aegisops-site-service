#!/usr/bin/env bash
set -euo pipefail
: "${MESSAGE:?A rollback phase marker is required}"
if [[ "$MESSAGE" == *'[staging-rollback:healthy]'* && "$MESSAGE" != *'[staging-rollback:failing]'* ]]; then
  expected=false
elif [[ "$MESSAGE" == *'[staging-rollback:failing]'* && "$MESSAGE" != *'[staging-rollback:healthy]'* ]]; then
  expected=true
else
  echo 'Exactly one rollback phase is required' >&2; exit 1
fi
grep -Fx "ARG AEGISOPS_FIXTURE_FAIL_HEALTH=$expected" Dockerfile
