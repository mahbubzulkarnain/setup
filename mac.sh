#!/usr/bin/env bash

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# brew doctor

# Install Xcode command line tools
xcode-select --install

echo "Update..."
brew update

echo "Upgrade..."
brew upgrade

echo "Install git..."
brew install git

echo "Install java..."
brew cask install java
# brew install maven
# brew install gradle

brew install wget
# brew cask install vlc
# brew cask install gimp
# brew install coreutils
# brew cask install qbittorrent

echo "Install markdown ide..."
brew cask install macdown

echo "Install iterm..."
# brew cask install iterm2
brew install zsh zsh-completions
wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh | bash

echo "Install NVM..."
brew install nvm

echo "Install NodeJS LTS Version"
nvm install v12.16.2

wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh | bash

echo "Install go..."
brew install go
go get golang.org/x/tools/cmd/godoc
go get github.com/golang/lint/golint

# echo "Install ruby..."
# echo "gem: --no-document" >> ~/.gemrc
# curl -L https://get.rvm.io | bash -s stable --auto-dotfiles --autolibs=enable --rails
# rvm get stable --autolibs=enable --auto-dotfiles
# rvm install 2.6.5
# rvm use 2.6.5 --default
# wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/gem.sh | bash

echo "Installing Development Tools..."
brew cask install insomnia
brew cask install altair-graphql-client
brew cask install dbeaver-community
brew install awscli
# brew cask install sequel-pro
# brew cask install postman

# brew cask install intellij-idea
# brew cask install webstorm
brew cask install goland

# brew cask install vyso
# brew cask install android-sdk
# brew cask install android-studio
# brew cask install expo-xde

# brew cask install google-cloud-sdk
# brew tap heroku/brew && brew install heroku
brew cask install ngrok

brew install docker
brew install postgres
brew install redis
# brew install php
brew install elasticsearch

brew tap mongodb/brew
brew install mongodb-community

echo "Install browser..."
brew cask install --appdir="/Applications" google-chrome
brew cask install --appdir="/Applications" tor-browser

echo "Install Social..."
brew cask install whatsapp
# brew cask install slack
# brew cask install skype
brew cask install spotify

brew cleanup
