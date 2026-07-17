#!/usr/bin/env bash
set -euo pipefail

run_remote() {
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$1" -o "$tmp"
    bash "$tmp"
    rm -f "$tmp"
}

install_vscode() {
    if command -v code &>/dev/null; then
        echo "VS Code already installed, skipping."
    else
        echo "Install VS Code..."
        sudo apt-get install -y apt-transport-https gpg
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f /tmp/packages.microsoft.gpg
        sudo apt-get update
        sudo apt-get install -y code
    fi
}

install_flutter_fvm() {
    # Flutter (via FVM, matches the alias/PATH setup in dotfile/zsh/.zshrc)
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
    export PATH="$HOME/fvm/bin:$PATH"
    if command -v fvm &>/dev/null; then
        echo "FVM already installed, skipping."
    else
        echo "Install FVM..."
        curl -fsSL https://fvm.app/install.sh | bash
    fi
    if fvm list 2>/dev/null | grep -q "stable"; then
        echo "Flutter (FVM stable) already installed, skipping."
    else
        echo "Install Flutter (stable) via FVM..."
        fvm install stable
        fvm global stable
        fvm flutter config --enable-linux-desktop
    fi
}

install_typora() {
    if snap list typora-alanzanattadev &>/dev/null; then
        echo "Typora already installed, skipping."
    else
        echo "Install markdown ide..."
        sudo snap install typora-alanzanattadev
    fi
}

install_flyenv() {
    # FlyEnv (https://github.com/xpf0000/FlyEnv)
    if dpkg -s flyenv >/dev/null 2>&1; then
        echo "FlyEnv already installed, skipping."
    else
        echo "Install FlyEnv..."
        case "$(dpkg --print-architecture)" in
            amd64) flyenv_arch="x64" ;;
            arm64) flyenv_arch="arm64" ;;
        esac
        set +o pipefail
        flyenv_deb_url=$(curl -fsSL https://api.github.com/repos/xpf0000/FlyEnv/releases/latest | grep -m1 -oE "https://github\.com/xpf0000/FlyEnv/releases/download/[^\"]*FlyEnv-[0-9.]+-${flyenv_arch}\.deb")
        set -o pipefail
        curl -fsSL -o /tmp/flyenv.deb "$flyenv_deb_url"
        sudo dpkg -i /tmp/flyenv.deb || sudo apt-get install -f -y
        rm -f /tmp/flyenv.deb
    fi
}

install_kali_tools() {
    if ! dpkg -s kali-linux-large >/dev/null 2>&1; then
        sudo apt-get install -y kali-linux-large
    fi
    if ! dpkg -s kali-win-kex >/dev/null 2>&1; then
        sudo apt-get install -y kali-win-kex
    fi
    if ! command -v sniper >/dev/null 2>&1; then
        echo "Install Sn1per..."
        mkdir -p ~/Sandbox && cd ~/Sandbox
        git clone https://github.com/1N3/Sn1per
        (cd Sn1per && bash install.sh)
    fi
}

install_ngrok() {
    if command -v ngrok &>/dev/null; then
        echo "ngrok already installed, skipping."
    else
        echo "Install ngrok..."
        curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y ngrok
    fi
}

install_chrome() {
    if dpkg -s google-chrome-stable &>/dev/null; then
        echo "Google Chrome already installed, skipping."
    else
        echo "Install Google Chrome..."
        curl -fsSL -o /tmp/google-chrome-stable.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i /tmp/google-chrome-stable.deb || sudo apt-get install -f -y
        rm -f /tmp/google-chrome-stable.deb
    fi
}

install_tor_browser() {
    if dpkg -s torbrowser-launcher &>/dev/null; then
        echo "Tor Browser already installed, skipping."
    else
        echo "Install Tor Browser..."
        sudo apt-get install -y torbrowser-launcher
    fi
}

install_spotify() {
    if snap list spotify &>/dev/null; then
        echo "Spotify already installed, skipping."
    else
        echo "Install Spotify..."
        sudo snap install spotify
    fi
}

install_bruno() {
    if snap list bruno &>/dev/null; then
        echo "Bruno already installed, skipping."
    else
        echo "Install Bruno..."
        sudo snap install bruno
    fi
}

echo "Update..."
sudo apt-get update

run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/cli.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/java.sh
run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/ai.sh

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            echo "Distro: $ID"
            sudo apt-get upgrade -y
            install_vscode
            install_flutter_fvm
            install_typora
            install_flyenv
            run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/docker.sh
            install_ngrok
            install_chrome
            install_tor_browser
            install_spotify
            install_bruno
            echo "WhatsApp: tidak ada client resmi untuk Linux, gunakan web.whatsapp.com di browser."
            ;;
        kali)
            echo "Distro: Kali"
            sudo apt-get upgrade -y
            install_kali_tools
            install_vscode
            install_flyenv
            ;;
        arch)
            echo "Distro Arch belum didukung otomatis, skip package-manager-specific steps."
            ;;
        fedora)
            echo "Distro Fedora belum didukung otomatis, skip package-manager-specific steps."
            ;;
        centos)
            echo "Distro CentOS belum didukung otomatis, skip package-manager-specific steps."
            ;;
        *)
            echo "Distro Linux lain belum didukung otomatis: $ID"
            ;;
    esac
else
    echo "Tidak dapat mendeteksi distro Linux, skip package-manager-specific steps." >&2
fi

# sudo apt-get install wget
# sudo apt-get install vlc
# sudo apt-get install gimp
# sudo apt-get install coreutils

# echo "Install snap..."
# sudo apt-get install snapd

# echo "Installing Development Tools..."
# sudo snap install postman
# sudo snap install altair
# sudo snap install dbeaver-ce --edge
# sudo snap install go
# sudo snap install aws-cli

# sudo snap install webstorm

# sudo apt-get install lib32z1 lib32ncurses5 lib32bz2-1.0 lib32stdc++6
# sudo snap install android-studio

# sudo snap install google-cloud-sdk
# sudo snap install heroku

# sudo apt-get install redis
# sudo apt-get install mongodb
# sudo apt-get install php
# sudo apt-get install golang

# echo "Install Social..."
# sudo snap install slack
# sudo snap install skype
