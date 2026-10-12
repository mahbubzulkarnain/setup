#!/usr/bin/env bash
set -euo pipefail

# plaesy spec-kit (https://github.com/plaesy/spec-kit): a pinned release binary, checked against its SHA-256.
# The upstream publishes no checksum file, so the digests are GitHub's release-asset digests for v0.0.1.
# To upgrade: check the new release, then update PLAESY_VERSION and every digest below together.
# A checksum mismatch stops the setup on purpose.

PLAESY_VERSION=v0.0.1

export PATH="$HOME/.local/bin:$PATH"

if command -v plaesy &>/dev/null; then
    echo "plaesy already installed, skipping."
    exit 0
fi

case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) asset=plaesy-darwin-arm64;  sha=a94dd7d2e9199c59a075db6510c9f89e8b8d618cdb0d1060bdb99ff5371b1245 ;;
    Linux-x86_64) asset=plaesy-linux-amd64;   sha=f55c2d9618971dcd6c4055a0a2702ba3e68108f7f6b880a028c4d5b1ca00eb40 ;;
    Linux-aarch64) asset=plaesy-linux-arm64;  sha=276eb539ce08bee94d9d3fa8904b1050cc7a79882515e642da08dbec1e88a963 ;;
    *)
        echo "Warning: no plaesy release for $(uname -s)-$(uname -m). Skipping." >&2
        exit 0
        ;;
esac

echo "Install plaesy spec-kit ${PLAESY_VERSION}..."
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL -o "$tmp" "https://github.com/plaesy/spec-kit/releases/download/${PLAESY_VERSION}/${asset}"

if command -v sha256sum &>/dev/null; then
    actual=$(sha256sum "$tmp" | cut -d' ' -f1)
else
    actual=$(shasum -a 256 "$tmp" | cut -d' ' -f1)
fi
if [[ "$actual" != "$sha" ]]; then
    echo "Checksum mismatch for $asset: expected $sha, got $actual" >&2
    exit 1
fi

mkdir -p "$HOME/.local/bin"
install -m 755 "$tmp" "$HOME/.local/bin/plaesy"
echo "plaesy installed to $HOME/.local/bin/plaesy"
