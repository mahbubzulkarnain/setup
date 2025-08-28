#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/wsl.sh)
    else
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/debian.sh)
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh)
fi

echo "Link start!!!"

#elif [[ "$OSTYPE" == "cygwin" ]]; then
#        # POSIX compatibility layer and Linux environment emulation for Windows
#        echo 'mac'
#elif [[ "$OSTYPE" == "msys" ]]; then
#        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
#        echo 'mac'
#elif [[ "$OSTYPE" == "win32" ]]; then
#        # I'm not sure this can happen.
#        echo 'mac'
#elif [[ "$OSTYPE" == "freebsd"* ]]; then
#        # ...
#        echo 'mac'
#else
#        # Unknown.
#        echo 'undefined'
#fi
