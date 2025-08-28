#!/usr/bin/env bash

if [ -d "$HOME/.sdkman" ]; then
    if ! command -v sdk >/dev/null 2>&1; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
else
    echo "Install SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi