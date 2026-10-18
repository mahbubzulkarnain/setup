# shellcheck shell=bash
# macOS PATH and env. Installed to ~/.config/bash/os-macos.sh.

if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

addpath "$HOME/.local/bin"
addpath "$HOME/.pub-cache/bin"
addpath "$HOME/bin"
addpath "$HOME/Library/Android/sdk/platform-tools"
addpath "$HOME/Library/Android/sdk/cmdline-tools/latest/bin"
export ANDROID_HOME="$HOME/Library/Android/sdk"
