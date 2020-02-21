#!/usr/bin/env bash

echo "Update..."
sudo apt-get update

echo "Upgrade..."
sudo apt-get upgrade

echo "Install git..."
sudo apt-get install git

echo "Install java..."
sudo apt-get install default-jre
sudo apt-get install default-jdk

sudo apt-get install wget
#sudo apt-get install vlc
#sudo apt-get install gimp
#sudo apt-get install coreutils

echo "Install markdown ide..."
sudo snap install typora-alanzanattadev

sudo apt-get install zsh
wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh | bash

echo "Install NVM..."
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

echo "Install NodeJS v10.16.0"
nvm install v10.16.0

wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh | bash
wget -O - https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/gem.sh | bash

echo "Install snap..."
sudo apt-get install snapd

echo "Installing Development Tools..."
sudo snap install insomnia
sudo snap install altair
sudo snap install dbeaver-ce --edge
sudo snap install go
sudo snap install aws-cli
#sudo snap install postman

sudo snap install webstorm

#sudo apt-get install lib32z1 lib32ncurses5 lib32bz2-1.0 lib32stdc++6
#sudo snap install android-studio

sudo snap install google-cloud-sdk
sudo snap install heroku

sudo snap install docker
sudo apt-get install redis
sudo apt-get install mongodb
sudo apt-get install php
sudo apt-get install golang

echo "Install google chrome..."
browser_tools_dir=~/Tools/browser
mkdir -p $browser_tools_dir && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O $browser_tools_dir/google-chrome-stable_current_amd64.deb
sudo dpkg -i $browser_tools_dir/google-chrome-stable_current_amd64.deb

sudo snap install tor

echo "Install Social..."
#sudo snap install slack
#sudo snap install skype
#sudo snap install spotify
