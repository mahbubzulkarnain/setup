#!/usr/bin/env bash
set -euo pipefail

install_formula() {
    if brew list "$1" &>/dev/null; then
        echo "$1 already installed, skipping."
    else
        echo "Install $1..."
        brew install "$1"
    fi
}

install_cask() {
    if brew list --cask "$1" &>/dev/null; then
        echo "$1 already installed, skipping."
    else
        echo "Install $1..."
        brew install --cask "$@"
    fi
}

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/brew.sh)
jenv add "$(/usr/libexec/java_home)"

# Install Xcode command line tools
if xcode-select -p &>/dev/null; then
    echo "Xcode command line tools already installed, skipping."
else
    xcode-select --install
fi

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)

# brew install --cask java
# brew install maven
# brew install gradle

# brew install wget
# brew cask install vlc
# brew cask install gimp
# brew install coreutils
# brew cask install qbittorrent

# echo "Install markdown ide..."
# brew cask install macdown

# Flutter (via FVM, matches the alias/PATH setup in dotfile/zsh/.zshrc)
install_formula fvm
if fvm list 2>/dev/null | grep -q "stable"; then
    echo "Flutter (FVM stable) already installed, skipping."
else
    echo "Install Flutter (stable) via FVM..."
    fvm install stable
    fvm global stable
    fvm flutter config --enable-macos-desktop
fi

echo "Install iterm..."
# brew cask install iterm2

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)

echo "Install NodeJS LTS Version"
nvm install --lts
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/ai.sh)

install_formula go
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/gomod.sh)

# echo "Install ruby..."
# echo "gem: --no-document" >> ~/.gemrc
# curl -L https://get.rvm.io | bash -s stable --auto-dotfiles --autolibs=enable --rails
# rvm get stable --autolibs=enable --auto-dotfiles
# rvm install 2.6.5
# rvm use 2.6.5 --default
# wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/gem.sh | bash

# echo "Install PHP..."
# brew install composer

echo "Installing Development Tools..."
install_cask visual-studio-code
install_cask insomnia
install_cask dbeaver-community
# brew cask install altair-graphql-client
# brew install awscli
# brew cask install sequel-pro
# brew cask install postman

# brew install kcat

# brew cask install intellij-idea
# brew cask install webstorm
install_cask goland

# brew cask install vysor
# brew cask install android-sdk
# brew cask install android-studio
# brew cask install expo-xde

# brew cask install google-cloud-sdk
# brew tap heroku/brew && brew install heroku
install_cask ngrok

install_formula docker
# brew install postgres
# brew install redis
# brew install php
# brew install elasticsearch

# brew tap mongodb/brew
# install_formula mongodb-community

# FlyEnv (https://github.com/xpf0000/FlyEnv)
install_cask flyenv

echo "Install browser..."
install_cask google-chrome --appdir="/Applications"
install_cask tor-browser --appdir="/Applications"

echo "Install Social..."
install_cask whatsapp
install_cask spotify
# brew cask install slack
# brew cask install skype

brew cleanup
