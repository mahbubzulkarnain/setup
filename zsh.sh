#!/usr/bin/env bash

echo "Install ohmyzsh..."
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

cd ~ || exit

git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

wget -q https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/zul.zsh-theme -O ~/.oh-my-zsh/themes/zul.zsh-theme
wget -q https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/.zshrc -O ~/.zshrc

source .zshrc
