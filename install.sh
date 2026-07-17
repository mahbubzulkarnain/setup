#!/usr/bin/env bash
set -euo pipefail

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/linux.sh)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh)
elif [[ -n "${MSYSTEM:-}" ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)
else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install manually or add support for it." >&2
    exit 1
fi

echo "Setup complete!"
