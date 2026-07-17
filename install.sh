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
    run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh
else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install manually or add support for it." >&2
    exit 1
fi

echo "Setup complete!"
