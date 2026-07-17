#!/usr/bin/env bash
set -euo pipefail

run_remote() {
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$1" -o "$tmp"
    bash "$tmp"
    rm -f "$tmp"
}

winget_install() {
    local id="$1"
    if winget.exe list --id "$id" -e --accept-source-agreements >/dev/null 2>&1; then
        echo "$id already installed, skipping."
    else
        echo "Install $id..."
        winget.exe install --id "$id" -e --accept-package-agreements --accept-source-agreements
    fi
}

run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/cli.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/ai.sh

# FlyEnv (https://github.com/xpf0000/FlyEnv)
if MSYS_NO_PATHCONV=1 reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "FlyEnv" >/dev/null 2>&1 || \
   MSYS_NO_PATHCONV=1 reg.exe query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "FlyEnv" >/dev/null 2>&1; then
    echo "FlyEnv already installed, skipping."
else
    echo "Install FlyEnv..."
    set +o pipefail
    flyenv_installer_url=$(curl -fsSL https://api.github.com/repos/xpf0000/FlyEnv/releases/latest | grep -m1 -oE 'https://github\.com/xpf0000/FlyEnv/releases/download/[^"]*/FlyEnv-Setup-[0-9.]+\.exe')
    set -o pipefail
    curl -fsSL -o /tmp/FlyEnv-Setup.exe "$flyenv_installer_url"
    # /S is not honored by this installer (verified live: it still requires
    # clicking through Next/Install/Finish) — no winget/choco package exists
    # either, so this step needs manual interaction once per machine.
    /tmp/FlyEnv-Setup.exe
    rm -f /tmp/FlyEnv-Setup.exe
fi

echo "Installing Development Tools..."
winget_install Ngrok.Ngrok
winget_install Bruno.Bruno

echo "Install browser..."
winget_install Google.Chrome
winget_install TorProject.TorBrowser

echo "Install Social..."
winget_install WhatsApp.WhatsApp
winget_install Spotify.Spotify
