#!/usr/bin/env bash
set -euo pipefail

# Bash as the interactive shell on macOS and Linux. The login shell is not changed.
# Installs zoxide and fzf via Homebrew, copies dotfile/bash/ to ~/.config/bash, writes ~/.bashrc,
# and sets bash as the VS Code terminal. Windows (Git Bash) is handled by windows.sh.
# Needs mise.sh first: the VS Code step runs node from mise.

RAW=https://raw.githubusercontent.com/mahbubzulkarnain/setup/master

run_remote() {
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$1" -o "$tmp"
    bash "$tmp"
    rm -f "$tmp"
}

export PATH="$HOME/.local/bin:$PATH"

install_tools() {
    if [[ "$OSTYPE" != "darwin"* && "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Unsupported OS (OSTYPE=$OSTYPE) for this script. Windows uses windows.sh." >&2
        exit 1
    fi

    if [[ "$OSTYPE" == "linux-gnu"* ]] && ! command -v brew &>/dev/null; then
        run_remote "$RAW/brew.sh"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # macOS ships bash 3.2 (2007). Homebrew's bash is current, and VS Code uses it below.
    local pkgs="zoxide fzf"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pkgs="bash $pkgs"
    fi
    for pkg in $pkgs; do
        if brew list "$pkg" &>/dev/null; then
            echo "$pkg already installed, skipping."
        else
            echo "Install $pkg via Homebrew..."
            brew install "$pkg"
        fi
    done
}

install_config() {
    local dir="$HOME/.config/bash" os_file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_file=os-macos.sh
    else
        os_file=os-linux.sh
    fi

    echo "Install bash config to $dir..."
    mkdir -p "$dir"
    for f in common.sh "$os_file"; do
        curl -fsSL "$RAW/dotfile/bash/$f" -o "$dir/$f"
    done

    # Keep an existing ~/.bashrc once as ~/.bashrc.bak before it is replaced
    local rc="$HOME/.bashrc" tmp
    tmp=$(mktemp)
    curl -fsSL "$RAW/dotfile/bash/bashrc" -o "$tmp"
    if [[ -f "$rc" ]] && ! cmp -s "$rc" "$tmp"; then
        cp "$rc" "$rc.bak"
        echo "Existing ~/.bashrc saved as ~/.bashrc.bak"
    fi
    mv -f "$tmp" "$rc"

    # Login shells (Terminal, SSH) read ~/.bash_profile, which has to load ~/.bashrc
    if ! grep -q '\.bashrc' "$HOME/.bash_profile" 2>/dev/null; then
        printf '\n# Load ~/.bashrc for login shells\n[ -f ~/.bashrc ] && . ~/.bashrc\n' >> "$HOME/.bash_profile"
    fi
}

set_vscode_terminal() {
    local settings os_key bash_path script theme
    script=$(mktemp)
    theme=$(mktemp)
    curl -fsSL "$RAW/dotfile/bash/vscode-terminal.js" -o "$script"
    curl -fsSL "$RAW/dotfile/terminal/theme.json" -o "$theme"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        settings="$HOME/Library/Application Support/Code/User/settings.json"
        os_key=osx
        # Homebrew's bash, not the 3.2 one in /bin
        bash_path="$(brew --prefix)/bin/bash"
    else
        settings="$HOME/.config/Code/User/settings.json"
        os_key=linux
        bash_path="$(command -v bash)"
    fi

    echo "Set bash as the VS Code terminal and apply best-practice settings..."
    mise exec -- node "$script" "$settings" "$os_key" "$bash_path" "$theme"
    rm -f "$script" "$theme"
}

echo "Install bash config..."
install_tools
install_config
set_vscode_terminal
echo "Bash setup complete. The login shell is unchanged."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "To make bash the default in Terminal: sudo sh -c 'echo $(brew --prefix)/bin/bash >> /etc/shells' && chsh -s $(brew --prefix)/bin/bash"
fi
