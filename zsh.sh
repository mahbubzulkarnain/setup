#!/usr/bin/env bash

if ! command -v zsh &>/dev/null; then
    echo  "Install ohmyzsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if ! command -v brew &>/dev/null; then
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/brew.sh)
    fi

    brew install fzf zsh-syntax-highlighting zsh-autosuggestions
    
    cd ~ || exit

    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    curl -o ~/.oh-my-zsh/themes/zul.zsh-theme https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/zul.zsh-theme
    curl -o ~/.zshrc https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/.zshrc 
fi

source ~/.zshrc