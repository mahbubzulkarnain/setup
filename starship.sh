#!/usr/bin/env bash
set -euo pipefail

# Starship prompt (https://starship.rs) for Nushell on macOS and Linux. Windows: windows.nu.
# Config lives in dotfile/starship/starship.toml and is copied to ~/.config/starship.toml.

export PATH="$HOME/.local/bin:$PATH"

if command -v starship &>/dev/null; then
    echo "starship already installed, skipping."
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Install starship via Homebrew..."
    brew install starship
else
    echo "Install starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

echo "Install starship config..."
mkdir -p ~/.config
curl -fsSL https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/starship/starship.toml -o ~/.config/starship.toml
