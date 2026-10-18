#!/usr/bin/env bash
set -euo pipefail

# mise (https://mise.jdx.dev) installs everything in dotfile/mise/config.toml:
# Node.js LTS, Go, Python, and the global npm/Go CLIs. Replaces nvm, gvm, and the per-OS installs.
# Windows is handled by windows.sh (same config file).

RAW=https://raw.githubusercontent.com/mahbubzulkarnain/setup/master

if command -v mise &>/dev/null; then
    echo "mise already installed, skipping."
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Install mise via Homebrew..."
    brew install mise
else
    echo "Install mise..."
    curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$PATH"

config_dir="$HOME/.config/mise"
mkdir -p "$config_dir"
echo "Install mise tools (node, go, python, global CLIs)..."
curl -fsSL "$RAW/dotfile/mise/config.toml" -o "$config_dir/config.toml"
mise install
# Kilo CLI follows "latest", so move it to the newest release on every run
mise upgrade "npm:@kilocode/cli"

# FVM (Flutter version manager) is installed with Dart from mise, so it works the same on every OS
echo "Install FVM (latest) via Dart pub..."
mise exec -- dart pub global activate fvm
