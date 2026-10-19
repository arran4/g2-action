#!/usr/bin/env bash
set -euo pipefail

: "${G2_SOURCE_DIR:?missing checked-out g2 source directory}"
: "${G2_SOURCE_SHA:?missing g2 source commit SHA}"

if [[ "${RUNNER_OS:-}" == "Windows" ]]; then
  install_dir="/c/g2"
  binary="g2.exe"
else
  install_dir="/opt/g2"
  binary="g2"
fi

# Build outside the privileged installation directory.
output="$G2_SOURCE_DIR/$binary"
(
  cd "$G2_SOURCE_DIR"
  go build -ldflags "-X main.version=ref-$G2_SOURCE_SHA" -o "$output" ./cmd/g2
)

if [[ "${RUNNER_OS:-}" == "Windows" ]]; then
  mkdir -p "$install_dir"
  install -m 755 "$output" "$install_dir/$binary"
else
  sudo mkdir -p "$install_dir"
  sudo install -m 755 "$output" "$install_dir/$binary"
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$install_dir" >> "$GITHUB_PATH"
else
  echo "Warning: GITHUB_PATH is not set; exported PATH applies only to this step"
  export PATH="$install_dir:$PATH"
fi

echo "Installed g2 from source commit $G2_SOURCE_SHA to $install_dir"
rm -rf -- "$G2_SOURCE_DIR"
