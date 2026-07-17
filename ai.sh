#!/usr/bin/env bash

# Hermes Agent (https://hermes-agent.nousresearch.com)
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ ! -d "$HOME/.hermes" ]]; then
        echo "Install Hermes Agent..."
        curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    fi
elif [[ -n "$MSYSTEM" ]]; then
    # Upstream installer refuses to run under MSYS/MinGW/Cygwin; only the
    # EXE desktop installer is offered for Windows.
    echo "Hermes Agent has no terminal installer for Windows, download the installer from https://hermes-agent.nousresearch.com"
fi
