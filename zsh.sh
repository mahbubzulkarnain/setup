#!/usr/bin/env bash
set -euo pipefail

if ! command -v zsh &>/dev/null; then
    echo "Install zsh..."
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        apt install -y zsh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install zsh
    elif [[ -n "${MSYSTEM:-}" ]]; then
        pacman -Sy --noconfirm zsh
    fi

    echo "Install ohmyzsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if [[ -n "${MSYSTEM:-}" ]]; then
        pacman -Sy --noconfirm unzip
        fzf_version=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        curl -fsSL -o /tmp/fzf.zip "https://github.com/junegunn/fzf/releases/download/v${fzf_version}/fzf-${fzf_version}-windows_amd64.zip"
        unzip -o /tmp/fzf.zip -d /tmp
        install -m 755 /tmp/fzf.exe /usr/bin/fzf
        rm -f /tmp/fzf.zip /tmp/fzf.exe
    else
        if ! command -v brew &>/dev/null; then
            bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/brew.sh)
        fi

        brew install fzf zsh-syntax-highlighting zsh-autosuggestions
    fi

    cd ~ || exit

    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    curl -o ~/.oh-my-zsh/themes/zul.zsh-theme https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/zul.zsh-theme
    curl -o ~/.zshrc https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/.zshrc
fi

source ~/.zshrc
