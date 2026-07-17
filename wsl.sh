#!/usr/bin/env bash

echo "Update..."
sudo apt-get update

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/java.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/ai.sh)

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
    flyenv_deb_url=$(curl -fsSL https://api.github.com/repos/xpf0000/FlyEnv/releases/latest | grep -m1 -oE "https://github\.com/xpf0000/FlyEnv/releases/download/[^\"]*FlyEnv-[0-9.]+-${flyenv_arch}\.deb")
    curl -fsSL -o /tmp/flyenv.deb "$flyenv_deb_url"
    sudo dpkg -i /tmp/flyenv.deb || sudo apt-get install -f -y
    rm -f /tmp/flyenv.deb
  fi
}

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu)
      echo "Ini Ubuntu"
      install_vscode
      install_flyenv
    ;;
    debian)
        echo "Ini Debian"
        install_vscode
        install_flyenv
    ;;
    kali)
      if ! dpkg -s kali-linux-large >/dev/null 2>&1; then
        sudo apt install -y kali-linux-large
      fi
      if ! dpkg -s kali-win-kex >/dev/null 2>&1; then
        sudo apt install -y kali-win-kex
      fi
      if ! command -v sniper >/dev/null 2>&1; then
        echo "Install Sn1per..."
        cd ~/Sandbox
        git clone https://github.com/1N3/Sn1per
        cd Sn1per
        bash install.sh
      fi
      install_vscode
      install_flyenv
    ;;
    arch)
      echo "Ini Arch Linux"
    ;;
    fedora)
      echo "Ini Fedora"
    ;;
    centos)
      echo "Ini CentOS"
    ;;
    *)
      echo "Distro Linux lain: $ID"
    ;;
  esac
else
  echo "Tidak dapat mendeteksi distro Linux"
fi