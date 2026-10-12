#!/usr/bin/env bash
set -euo pipefail

# plaesy spec-kit (https://github.com/plaesy/spec-kit): release binary, verified against the release's SHA256SUMS.
# The version is fixed (PLAESY_VERSION) while the project is in development; the checksum is read from that
# release on every install, so the binary is checked against whatever the release currently publishes.
# Upgrading: change PLAESY_VERSION. A missing or mismatched checksum stops the setup on purpose.

PLAESY_VERSION=v0.0.1
SUMS_URL="https://github.com/plaesy/spec-kit/releases/download/${PLAESY_VERSION}/SHA256SUMS"

export PATH="$HOME/.local/bin:$PATH"

if command -v plaesy &>/dev/null; then
    echo "plaesy already installed, skipping."
    exit 0
fi

case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) asset=plaesy-darwin-arm64 ;;
    Linux-x86_64) asset=plaesy-linux-amd64 ;;
    Linux-aarch64) asset=plaesy-linux-arm64 ;;
    *)
        echo "Warning: no plaesy release for $(uname -s)-$(uname -m). Skipping." >&2
        exit 0
        ;;
esac

echo "Install plaesy spec-kit ${PLAESY_VERSION}..."
sums=$(curl -fsSL "$SUMS_URL") || { echo "Could not download SHA256SUMS for ${PLAESY_VERSION}. Setup stopped." >&2; exit 1; }
expected=$(awk -v name="$asset" '$2 == name { print $1 }' <<< "$sums")
if [[ -z "$expected" ]]; then
    echo "No checksum for ${asset} in SHA256SUMS. Setup stopped." >&2
    exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL -o "$tmp" "https://github.com/plaesy/spec-kit/releases/download/${PLAESY_VERSION}/${asset}"

if command -v sha256sum &>/dev/null; then
    actual=$(sha256sum "$tmp" | cut -d' ' -f1)
else
    actual=$(shasum -a 256 "$tmp" | cut -d' ' -f1)
fi
if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for ${asset}: SHA256SUMS says ${expected}, got ${actual}. Setup stopped." >&2
    exit 1
fi

mkdir -p "$HOME/.local/bin"
install -m 755 "$tmp" "$HOME/.local/bin/plaesy"
echo "plaesy installed to $HOME/.local/bin/plaesy (SHA-256 verified)"
