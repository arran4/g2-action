#!/usr/bin/env bash
set -euo pipefail

version="${G2_VERSION:-latest}"
ref="${G2_SOURCE_REF:-}"

# Keep release installation backward compatible. All non-release values of
# version are git refs; source-ref explicitly disambiguates tag-shaped refs.
if [[ -z "$ref" ]]; then
  if [[ "$version" == "latest" || "$version" =~ ^v[0-9]+(\.[0-9]+){0,2}([.-][A-Za-z0-9.-]+)?$ ]]; then
    echo "Installing g2 release: $version"
    echo "from_source=false" >> "$GITHUB_OUTPUT"
    exit 0
  fi
  ref="$version"
fi

if [[ "$ref" == -* || "$ref" == *$'\n'* || "$ref" == *$'\r'* ]]; then
  echo "::error::Invalid g2 source ref" >&2
  exit 1
fi

echo "Fetching g2 source ref: $ref"
source_dir=$(mktemp -d)
git -C "$source_dir" init -q
git -C "$source_dir" remote add origin https://github.com/arran4/g2.git
git -C "$source_dir" fetch --quiet --depth=1 --no-tags origin "$ref"
git -C "$source_dir" checkout --quiet --detach FETCH_HEAD
sha=$(git -C "$source_dir" rev-parse --short=12 HEAD)

# setup-go is a Node action and requires a Windows-native directory on Windows.
if [[ "${RUNNER_OS:-}" == "Windows" ]]; then
  source_dir=$(cygpath -m "$source_dir")
fi

{
  echo "from_source=true"
  echo "source_dir=$source_dir"
  echo "source_sha=$sha"
} >> "$GITHUB_OUTPUT"
echo "Checked out g2 at $sha"
