# shellcheck shell=bash
# Windows (Git Bash) PATH and env. Installed to ~/.config/bash/os-windows.sh.
# Git Bash inherits the Windows PATH, so most tools are already found. This covers the rest.

# Node version manager (fnm), kept from the old ~/.bashrc. Its env output is cached in ~/.cache/shell-init.
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
    addpath "$FNM_PATH"
    fnm_cache="$HOME/.cache/shell-init/fnm.sh"
    if [ ! -s "$fnm_cache" ]; then
        mkdir -p "$(dirname "$fnm_cache")"
        fnm env --shell bash > "$fnm_cache"
    fi
    . "$fnm_cache"
fi

# C:\Users\me\AppData\Local -> /c/Users/me/AppData/Local, without starting cygpath (a process per call)
LOCAL_APP="${LOCALAPPDATA//\\//}"
LOCAL_APP="/${LOCAL_APP%%:*}${LOCAL_APP#*:}"
LOCAL_APP="${LOCAL_APP/\/C\//\/c\/}"
addpath "$HOME/fvm/default/bin"
addpath "$HOME/.local/bin"
addpath "$HOME/bin"
addpath "$LOCAL_APP/Pub/Cache/bin"
addpath "$LOCAL_APP/Microsoft/WinGet/Links"
addpath "$LOCAL_APP/Plaesy/bin"
addpath "$LOCAL_APP/Android/Sdk/platform-tools"
addpath "$LOCAL_APP/Android/Sdk/cmdline-tools/latest/bin"
export ANDROID_HOME="$LOCAL_APP/Android/Sdk"

# JDK from mise (Android tools and Gradle read JAVA_HOME). Read the "global" link mise keeps,
# so startup does not run mise again.
JAVA_LINK="$LOCAL_APP/mise/installs/java/global"
[ -d "$JAVA_LINK" ] && export JAVA_HOME="$JAVA_LINK"

# open [path]: like macOS. Windows has no open command, so this shows the folder in File Explorer.
open() { explorer.exe "$(cygpath -w "${1:-.}")"; }

# fvm is a .bat file on Windows, and Git Bash cannot run .bat files by name.
# Run it through cmd so the flutter, dart, and pub aliases in common.sh work.
fvm() { cmd //c fvm "$@"; }
