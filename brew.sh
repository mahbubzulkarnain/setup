#!/usr/bin/env bash

if command -v brew &>/dev/null; then
    echo "Homebrew already installed, skipping."
else
    echo "Install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Update..."
brew update

echo "Upgrade..."
brew upgrade

if brew list jenv &>/dev/null; then
    echo "jenv already installed, skipping."
else
    echo "Install java..."
    brew install jenv
fi

if brew list nvm &>/dev/null; then
    echo "nvm already installed, skipping."
else
    echo "Install NVM..."
    brew install nvm
fi