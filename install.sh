#!/usr/bin/env bash

mkdir ~/Sandbox
mkdir ~/Project
mkdir ~/Tools
mkdir ~/Learn
mkdir ~/Example
mkdir ~/Systems

sudo chown -R $(whoami) /usr/local/bin
cd ~

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/debian.sh)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh)
fi

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)

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
