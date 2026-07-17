#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/ai.sh)

# FlyEnv (https://github.com/xpf0000/FlyEnv)
if MSYS_NO_PATHCONV=1 reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "FlyEnv" >/dev/null 2>&1 || \
   MSYS_NO_PATHCONV=1 reg.exe query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "FlyEnv" >/dev/null 2>&1; then
    echo "FlyEnv already installed, skipping."
else
    echo "Install FlyEnv..."
    flyenv_installer_url=$(curl -fsSL https://api.github.com/repos/xpf0000/FlyEnv/releases/latest | grep -m1 -oE 'https://github\.com/xpf0000/FlyEnv/releases/download/[^"]*/FlyEnv-Setup-[0-9.]+\.exe')
    curl -fsSL -o /tmp/FlyEnv-Setup.exe "$flyenv_installer_url"
    /tmp/FlyEnv-Setup.exe
    rm -f /tmp/FlyEnv-Setup.exe
fi
