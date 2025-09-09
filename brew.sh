#!/usr/bin/env bash

echo "Install Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Update..."
brew update

echo "Upgrade..."
brew upgrade

echo "Install java..."
brew install jenv

echo "Install NVM..."
brew install nvm