#!/usr/bin/env bash
set -euo pipefail

# Hermes Agent (https://hermes-agent.nousresearch.com)
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ ! -d "$HOME/.hermes" ]]; then
        echo "Install Hermes Agent..."
        curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    fi
fi
