#!/usr/bin/env bash

echo "Update..."
sudo apt-get update

echo "Upgrade..."
sudo apt-get upgrade -y

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)

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

# sudo apt-get install wget
# sudo apt-get install vlc
# sudo apt-get install gimp
# sudo apt-get install coreutils

if snap list typora-alanzanattadev &>/dev/null; then
    echo "Typora already installed, skipping."
else
    echo "Install markdown ide..."
    sudo snap install typora-alanzanattadev
fi

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/ai.sh)

# FlyEnv (https://github.com/xpf0000/FlyEnv)
if dpkg -s flyenv >/dev/null 2>&1; then
    echo "FlyEnv already installed, skipping."
else
    echo "Install FlyEnv..."
    case "$(dpkg --print-architecture)" in
        amd64) flyenv_arch="x64" ;;
        arm64) flyenv_arch="arm64" ;;
    esac
    flyenv_deb_url=$(curl -fsSL https://api.github.com/repos/xpf0000/FlyEnv/releases/latest | grep -m1 -oE "https://github\.com/xpf0000/FlyEnv/releases/download/[^\"]*FlyEnv-[0-9.]+-${flyenv_arch}\.deb")
    curl -fsSL -o /tmp/flyenv.deb "$flyenv_deb_url"
    sudo dpkg -i /tmp/flyenv.deb || sudo apt-get install -f -y
    rm -f /tmp/flyenv.deb
fi

# echo "Install snap..."
# sudo apt-get install snapd

# echo "Installing Development Tools..."
# sudo snap install postman
# sudo snap install insomnia
# sudo snap install altair
# sudo snap install dbeaver-ce --edge
# sudo snap install go
# sudo snap install aws-cli

# sudo snap install webstorm

# sudo apt-get install lib32z1 lib32ncurses5 lib32bz2-1.0 lib32stdc++6
# sudo snap install android-studio

# sudo snap install google-cloud-sdk
# sudo snap install heroku

# sudo snap install docker
# sudo apt-get install redis
# sudo apt-get install mongodb
# sudo apt-get install php
# sudo apt-get install golang

# echo "Install google chrome..."
# browser_tools_dir=~/Tools/browser
# mkdir -p $browser_tools_dir && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $browser_tools_dir/google-chrome-stable_current_amd64.deb
# sudo dpkg -i $browser_tools_dir/google-chrome-stable_current_amd64.deb

# sudo snap install tor

# echo "Install Social..."
# sudo snap install slack
# sudo snap install skype
# sudo snap install spotify
