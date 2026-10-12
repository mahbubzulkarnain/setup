#!/usr/bin/env bash
set -euo pipefail

run_remote() {
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$1" -o "$tmp"
    bash "$tmp"
    rm -f "$tmp"
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/linux.sh
elif [[ "$OSTYPE" == "darwin"* ]]; then
    run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh
elif [[ -n "${MSYSTEM:-}" ]]; then
    # Windows (Git Bash): install.ps1 bootstraps Nushell and runs windows.nu, the one Windows setup
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/install.ps1)"
else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install manually or add support for it." >&2
    exit 1
fi

echo "Setup complete!"
