#!/usr/bin/env bash
set -euo pipefail

# Nushell as an interactive shell on macOS and Linux (the login shell stays as it is).
# Installs nushell, zoxide, and fzf, copies dotfile/nushell/ to Nushell's config dir,
# and sets it as the VS Code terminal. Nushell is not POSIX, so it is not made the login shell.
# Windows (including Git Bash) is handled by windows.nu.

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
        echo "Unsupported OS (OSTYPE=$OSTYPE) for this script. Windows uses windows.nu." >&2
        exit 1
    fi

    if [[ "$OSTYPE" == "linux-gnu"* ]] && ! command -v brew &>/dev/null; then
        run_remote "$RAW/brew.sh"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    for pkg in nushell zoxide fzf; do
        if brew list "$pkg" &>/dev/null; then
            echo "$pkg already installed, skipping."
        else
            echo "Install $pkg via Homebrew..."
            brew install "$pkg"
        fi
    done
}

install_config() {
    local cfg_dir
    # shellcheck disable=SC2016 # $nu is a Nushell variable, not a shell one
    cfg_dir=$(nu -c 'print $nu.default-config-dir')

    echo "Install Nushell config to $cfg_dir..."
    mkdir -p "$cfg_dir"
    for f in env.nu config.nu; do
        curl -fsSL "$RAW/dotfile/nushell/$f" -o "$cfg_dir/$f"
    done
}

set_vscode_terminal() {
    local settings os_key script
    script=$(mktemp)
    curl -fsSL "$RAW/dotfile/nushell/vscode.nu" -o "$script"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        settings="$HOME/Library/Application Support/Code/User/settings.json"
        os_key=osx
    else
        settings="$HOME/.config/Code/User/settings.json"
        os_key=linux
    fi

    echo "Set Nushell as the VS Code terminal and apply best-practice settings..."
    VSCODE_SETTINGS="$settings" VSCODE_OS="$os_key" nu "$script"
    rm -f "$script"
}

echo "Install Nushell..."
install_tools
install_config
set_vscode_terminal
echo "Nushell setup complete. Login shell is unchanged. Start nu from your terminal profile or VS Code."
