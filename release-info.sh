#!/usr/bin/env bash
# Resolve a published release tag. Only the validated tag is written to stdout.
set -euo pipefail

api_url=$1
token=${2:-}

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required to parse GitHub release metadata." >&2
  exit 1
fi

curl_args=(--silent --show-error --location --retry 3 --retry-max-time 45
  --connect-timeout 10 --max-time 20 --write-out '\n%{http_code}'
  --header 'Accept: application/vnd.github+json')
if [[ -n "$token" ]]; then
  curl_args+=(--header "Authorization: Bearer $token")
fi

# Keep the response body and status separate without dumping either credentials
# or the complete response into the Actions log. curl retries transient statuses
# (including 429 and 5xx) and honors Retry-After where supported.
if response=$(curl "${curl_args[@]}" "$api_url"); then
  status=${response##*$'\n'}
  body=${response%$'\n'*}
else
  rc=$?
  echo "Error: GitHub release metadata request failed (curl exit $rc)." >&2
  exit 1
fi

if [[ "$status" != 200 ]]; then
  message=$(jq -c '.message | strings' <<< "$body" 2>/dev/null || true)
  printf 'Error: GitHub release metadata request returned HTTP %s.\n' "$status" >&2
  if [[ -n "$message" ]]; then
    printf 'GitHub API message: %s\n' "$message" >&2
  fi
  exit 1
fi

if ! tag=$(jq -er 'select(type == "object") | .tag_name | select(type == "string" and length > 0)' <<< "$body" 2>/dev/null); then
  echo "Error: GitHub release metadata returned HTTP 200 without a valid tag_name (malformed JSON or unexpected response)." >&2
  exit 1
fi
printf '%s\n' "$tag"
