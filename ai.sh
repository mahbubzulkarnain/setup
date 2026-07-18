#!/usr/bin/env bash
set -euo pipefail

# Hermes Agent (https://hermes-agent.nousresearch.com)
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ ! -d "$HOME/.hermes" ]]; then
        echo "Install Hermes Agent..."
        curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    fi
elif [[ -n "${MSYSTEM:-}" ]]; then
    # Upstream's install.sh refuses to run under MSYS/MinGW/Cygwin, but Hermes
    # now ships a native Windows installer (PowerShell, no WSL required).
    if [[ ! -d "${LOCALAPPDATA}/hermes" ]]; then
        echo "Install Hermes Agent..."
        powershell.exe -NoProfile -Command "iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
    fi
fi
