#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/wsl.sh)
    else
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/debian.sh)
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh)
elif [[ -n "$MSYSTEM" ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)
fi

echo "Link start!!!"
