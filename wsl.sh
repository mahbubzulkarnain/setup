#!/usr/bin/env bash

echo "Update..."
sudo apt-get update

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)

if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu)
      echo "Ini Ubuntu"
    ;;
    debian)
        echo "Ini Debian"
    ;;
    kali)
        sudo apt install -y kali-linux-large kali-win-kex
        if ! command -v sniper >/dev/null 2>&1; then
            echo "Install Sn1per..."
            cd ~/Sandbox
            git clone https://github.com/1N3/Sn1per
            cd Sn1per
            bash install.sh
        fi
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