# shellcheck shell=bash
# Linux PATH and env. Installed to ~/.config/bash/os-linux.sh.

if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

addpath "$HOME/.local/bin"
addpath "$HOME/.pub-cache/bin"
addpath "$HOME/fvm/bin"
addpath "$HOME/.fvm_flutter/bin"
addpath "$HOME/Android/Sdk/platform-tools"
addpath "$HOME/Android/Sdk/cmdline-tools/latest/bin"
export ANDROID_HOME="$HOME/Android/Sdk"
