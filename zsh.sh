#!/usr/bin/env bash

echo "Install ohmyzsh..."
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

cd ~ || exit

git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

curl -o ~/.oh-my-zsh/themes/zul.zsh-theme https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/zul.zsh-theme
curl -o ~/.zshrc https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/.zshrc 

source .zshrc
