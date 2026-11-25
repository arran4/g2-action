#!/usr/bin/env bash
set -e

VERSION="${1:-latest}"
GITHUB_TOKEN="${2}"

echo "Starting g2 setup..."
echo "Requested version: $VERSION"

# Detect OS
OS="linux"
if [ "$RUNNER_OS" = "macOS" ]; then
  OS="darwin"
elif [ "$RUNNER_OS" = "Windows" ]; then
  OS="windows"
fi

# Detect Architecture
ARCH="amd64"
if [ "$RUNNER_ARCH" = "ARM64" ]; then
  ARCH="arm64"
elif [ "$RUNNER_ARCH" = "ARM32" ]; then
  ARCH="armv7"
fi

echo "Detected OS: $OS"
echo "Detected Arch: $ARCH"

# Fetch release info
if [ "$VERSION" = "latest" ]; then
  API_URL="https://api.github.com/repos/arran4/g2/releases/latest"
else
  API_URL="https://api.github.com/repos/arran4/g2/releases/tags/${VERSION}"
fi

echo "Fetching release info from: $API_URL"

TAG_NAME=$(bash "$(dirname "${BASH_SOURCE[0]}")/release-info.sh" "$API_URL" "$GITHUB_TOKEN")

echo "Found release tag: $TAG_NAME"

# Determine download URL
VERSION_WITHOUT_V="${TAG_NAME#v}"

FILE_EXT="tar.gz"
if [ "$OS" = "windows" ]; then
  FILE_EXT="zip"
fi

FILENAME="g2_${VERSION_WITHOUT_V}_${OS}_${ARCH}.${FILE_EXT}"
DOWNLOAD_URL="https://github.com/arran4/g2/releases/download/${TAG_NAME}/${FILENAME}"

echo "Downloading from: $DOWNLOAD_URL"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download the file
curl --silent --show-error --location --fail --retry 3 --retry-max-time 45 --connect-timeout 10 --max-time 120 -o "$FILENAME" "$DOWNLOAD_URL" || {
  echo "Error: Failed to download $DOWNLOAD_URL"
  exit 1
}

echo "Download successful."

# Extract and install
INSTALL_DIR="/opt/g2"
if [ "$OS" = "windows" ]; then
  # On Windows runners, using Git Bash means /c/ is usually C:\
  INSTALL_DIR="/c/g2"
  mkdir -p "$INSTALL_DIR"
else
  sudo mkdir -p "$INSTALL_DIR"
fi

echo "Extracting archive to $INSTALL_DIR..."
if [ "$OS" = "windows" ]; then
  unzip -q "$FILENAME" -d "$INSTALL_DIR"
else
  sudo tar -xzf "$FILENAME" -C "$INSTALL_DIR"
fi

# Make binary executable
if [ "$OS" != "windows" ]; then
  sudo chmod +x "$INSTALL_DIR/g2"
fi

# Add to GITHUB_PATH
if [ -n "$GITHUB_PATH" ]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
  echo "Added $INSTALL_DIR to GITHUB_PATH"
else
  echo "Warning: GITHUB_PATH is not set. Assuming local run."
  export PATH="$INSTALL_DIR:$PATH"
fi

echo "Successfully installed g2 $TAG_NAME"
"$INSTALL_DIR/g2" --help || true
