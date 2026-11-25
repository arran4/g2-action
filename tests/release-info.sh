#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export PATH="$tmp:$PATH"
export MOCK_ARGS="$tmp/args"

cat > "$tmp/curl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_ARGS"
if [[ "${MOCK_EXIT:-0}" != 0 ]]; then
  exit "$MOCK_EXIT"
fi
printf '%s\n%s' "$MOCK_BODY" "$MOCK_STATUS"
MOCK
chmod +x "$tmp/curl"
url=https://api.github.com/repos/arran4/g2/releases/latest
run() {
  bash "$root/release-info.sh" "$url" "${1:-}"
}
export MOCK_STATUS=200 MOCK_BODY='{"tag_name":"v0.0.108","name":"example"}'
[[ $(run) == v0.0.108 ]]
grep -Fx -- '--retry' "$MOCK_ARGS"
grep -Fx -- '--retry-max-time' "$MOCK_ARGS"
! grep -F -- 'Authorization:' "$MOCK_ARGS"
[[ $(run test-token) == v0.0.108 ]]
grep -Fx -- 'Authorization: Bearer test-token' "$MOCK_ARGS"
export MOCK_BODY=$'{\n  "tag_name" : "v0.0.107"\n}'
[[ $(run) == v0.0.107 ]]

expect_failure() {
  local expected=$1
  if run test-token > "$tmp/out" 2> "$tmp/err"; then
    echo "Expected release lookup to fail: $expected" >&2
    exit 1
  fi
  [[ ! -s "$tmp/out" ]]
  grep -F -- "$expected" "$tmp/err"
  ! grep -F -- 'test-token' "$tmp/err"
}

export MOCK_STATUS=403 MOCK_BODY='{"message":"API rate limit exceeded"}'
expect_failure 'HTTP 403'
grep -F 'API rate limit exceeded' "$tmp/err"
export MOCK_STATUS=429 MOCK_BODY='{"message":"Too many requests"}'
expect_failure 'HTTP 429'
export MOCK_STATUS=503 MOCK_BODY='<html>Unavailable</html>'
expect_failure 'HTTP 503'
export MOCK_STATUS=404 MOCK_BODY='{"message":"Not Found"}'
expect_failure 'HTTP 404'
export MOCK_STATUS=200 MOCK_BODY='{"message":"unexpected"}'
expect_failure 'without a valid tag_name'
export MOCK_BODY='{"tag_name":null}'
expect_failure 'without a valid tag_name'
export MOCK_BODY='{"tag_name":""}'
expect_failure 'without a valid tag_name'
export MOCK_BODY='not JSON'
expect_failure 'without a valid tag_name'
export MOCK_EXIT=28
expect_failure 'curl exit 28'
echo 'Release metadata tests passed.'
