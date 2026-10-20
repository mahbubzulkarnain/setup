# shellcheck shell=bash
# Windows (Git Bash) PATH and env. Installed to ~/.config/bash/os-windows.sh.
# Git Bash inherits the Windows PATH, so most tools are already found. This covers the rest.

# Node version manager (fnm), kept from the old ~/.bashrc
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    addpath "$FNM_PATH"
    eval "$(fnm env --shell bash)"
fi

LOCAL_APP="$(cygpath -u "$LOCALAPPDATA")"
addpath "$HOME/fvm/default/bin"
addpath "$HOME/.local/bin"
addpath "$HOME/bin"
addpath "$LOCAL_APP/Pub/Cache/bin"
addpath "$LOCAL_APP/Microsoft/WinGet/Links"
addpath "$LOCAL_APP/Plaesy/bin"
addpath "$LOCAL_APP/Android/Sdk/platform-tools"
addpath "$LOCAL_APP/Android/Sdk/cmdline-tools/latest/bin"
export ANDROID_HOME="$LOCAL_APP/Android/Sdk"

# JDK from mise (Android tools and Gradle read JAVA_HOME)
if command -v mise >/dev/null 2>&1; then
    JAVA_HOME="$(mise where java 2>/dev/null | tr -d '\r')"
    if [ -n "$JAVA_HOME" ]; then export JAVA_HOME; JAVA_HOME="$(cygpath -u "$JAVA_HOME")"; fi
fi

# fvm is a .bat file on Windows, and Git Bash cannot run .bat files by name.
# Run it through cmd so the flutter, dart, and pub aliases in common.sh work.
fvm() { cmd //c fvm "$@"; }
