#!/usr/bin/env bash
set -euo pipefail

if [ -d "$HOME/.sdkman" ]; then
    if ! command -v sdk >/dev/null 2>&1; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
else
    echo "Install SDKMAN..."
    curl -fsSL "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi