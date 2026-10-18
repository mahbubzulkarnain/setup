#!/usr/bin/env bash
set -euo pipefail

# Claude Code (https://code.claude.com) with Anthropic's native installer (the recommended method).
# It installs to ~/.local/bin/claude and updates itself. Windows: windows.sh runs the matching install.ps1.

export PATH="$HOME/.local/bin:$PATH"

if command -v claude &>/dev/null; then
    echo "Claude Code already installed, skipping."
    exit 0
fi

echo "Install Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash
