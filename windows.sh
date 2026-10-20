#!/usr/bin/env bash
# Windows setup, run in Git Bash. Same steps and checks as the earlier Nushell version.
# Usage: bash windows.sh [--dry-run]
# install.ps1 installs Git for Windows and runs this file. Admin steps ask for one UAC prompt each.
set -euo pipefail

RAW=https://raw.githubusercontent.com/mahbubzulkarnain/setup/master
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
DRY=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY=1
    echo "Dry run: no changes will be made."
fi

USER_HOME="$(cygpath -u "$USERPROFILE")"
LOCAL_APP="$(cygpath -u "$LOCALAPPDATA")"
TEMP_DIR="$(cygpath -u "$TEMP")"
PLAESY_DIR="$LOCAL_APP/Plaesy/bin"
MISE_SHIMS="$LOCAL_APP/mise/shims"
PUB_BIN="$LOCAL_APP/Pub/Cache/bin"
FVM_BIN="$USER_HOME/fvm/default/bin"
PLAESY_VERSION=v0.0.1
ANDROID_CMDLINE_ZIP=https://dl.google.com/android/repository/commandlinetools-win-16111833_latest.zip
ANDROID_PACKAGES=(platform-tools platforms/android-36 build-tools/36.1.0)
VS_CPP=Microsoft.VisualStudio.Component.VC.Tools.x86.x64
VS_ATL=Microsoft.VisualStudio.Component.VC.ATL

# winget package id, then the command used to check whether it is installed (empty: ask winget)
PACKAGES=(
    "Git.Git git"
    "GitHub.cli gh"
    "BurntSushi.ripgrep.MSVC rg"
    "sharkdp.fd fd"
    "sharkdp.bat bat"
    "JesseDuffield.lazygit lazygit"
    "jdx.mise mise"
    "Starship.Starship starship"
    "ajeetdsouza.zoxide zoxide"
    "junegunn.fzf fzf"
    "ezwinports.make make"
    "vim.vim vim"
    # Apps (same set as mac.sh and linux.sh)
    "Microsoft.VisualStudioCode code"
    "Google.Chrome -"
    "Bruno.Bruno -"
    "Docker.DockerDesktop -"
    "Ngrok.Ngrok ngrok"
    "TorProject.TorBrowser -"
    "Spotify.Spotify -"
    "Amazon.AWSCLI aws"
    "Kubernetes.kubectl kubectl"
)

say() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() {
    printf '%s\n' "$*" >&2
    exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

# Run a PowerShell command from Git Bash, without the carriage returns Windows adds
winps() { powershell.exe -NoProfile -Command "$1" | tr -d '\r'; }

# Repo file from this checkout when run inside it, otherwise from GitHub master
fetch() {
    if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$1" ]]; then
        cat "$SCRIPT_DIR/$1"
    else
        curl -fsSL "$RAW/$1"
    fi
}

# dart pub global activate makes fvm.bat, which Git Bash can't run by name. cmd runs it.
fvm() {
    # fvm.bat runs dart, which mise provides. Put dart on the PATH cmd sees, then call fvm.bat
    # fvm also runs git, which lives in Program Files (a space, so use the short path)
    local dart_win fvm_win git_win win_path
    dart_win="$(cygpath -w "$(mise where dart | tr -d '\r')")\\bin"
    fvm_win="$(cygpath -w "$PUB_BIN")\\fvm.bat"
    git_win="$(cygpath -d "$(cygpath -u "$PROGRAMFILES")/Git/cmd")"
    # Git Bash's PATH has Unix paths cmd can't read (PowerShell, where.exe), so give cmd the Windows PATH
    win_path="$(winps "[Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User'))")"
    PATH="$win_path" "$(cygpath -u "$SYSTEMROOT")/System32/cmd.exe" //c "set PATH=$dart_win;$git_win;%PATH% && $fvm_win $*"
}

# Reload PATH from the registry so tools installed earlier in this run are found
refresh_path() {
    local machine user
    machine="$(winps "[Environment]::GetEnvironmentVariable('Path','Machine')")"
    user="$(winps "[Environment]::GetEnvironmentVariable('Path','User')")"
    PATH="$PATH:$(cygpath -p -u "$machine;$user")"
}

winget_install() {
    local id="$1" cmd="$2" installed=0
    if [[ "$cmd" != "-" ]]; then
        have "$cmd" && installed=1
    else
        winget list --id "$id" --exact --accept-source-agreements >/dev/null 2>&1 && installed=1
    fi
    if [[ $installed -eq 1 ]]; then
        say "$id already installed, skipping."
        return 0
    fi

    say "Install $id..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    # One failed app must not stop the rest of the setup. It is reported and can be re-run.
    if ! winget install --id "$id" --exact --silent --accept-package-agreements --accept-source-agreements; then
        warn "winget failed for $id. Re-run setup to retry."
    fi
    refresh_path
}

ensure_hermes() {
    if [[ -d "$LOCAL_APP/hermes" ]]; then
        say "Hermes Agent already installed, skipping."
        return 0
    fi
    say "Install Hermes Agent..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    winps "iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
}

# Node.js, Go, Python, and global CLIs from dotfile/mise/config.toml (same file mise.sh uses)
mise_tools() {
    say "Install mise tools (node, go, python, global CLIs)..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    mkdir -p "$USER_HOME/.config/mise"
    fetch dotfile/mise/config.toml > "$USER_HOME/.config/mise/config.toml"
    mise install
    # Kilo CLI follows "latest", so move it to the newest release on every run
    mise upgrade "npm:@kilocode/cli"
    # FVM (Flutter version manager) via Dart from mise
    mise exec -- dart pub global activate fvm
    # Shims for global npm CLIs (n8n, pm2, ...) so apps that don't run a shell (FlyEnv) can find them
    mise reshim
}

# find-skills agent skill (vercel-labs/skills), installed globally so every agent can discover skills
find_skills() {
    say "Install find-skills skill (global)..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    mise exec -- npx -y skills add vercel-labs/skills --skill find-skills -g -y
}

git_config() {
    if ! have git; then
        warn "git not found, skipping git config."
        return 0
    fi

    local ignore_file current name
    ignore_file="$(cygpath -m "$USER_HOME")/.gitignore_global"
    current="$(git config --global --get core.excludesfile || true)"
    if [[ "$current" != "$ignore_file" ]]; then
        say "Setting up Git global..."
        if [[ $DRY -eq 0 ]]; then
            fetch dotfile/gitignore/.gitignore_global > "$USER_HOME/.gitignore_global"
            git config --global core.excludesfile "$ignore_file"
        fi
    fi

    name="$(git config --global --get user.name || true)"
    if [[ "$name" != "Mahbub Zulkarnain" ]]; then
        say "Setting up Git user.name..."
        if [[ $DRY -eq 0 ]]; then
            git config --global user.name "Mahbub Zulkarnain"
        fi
    fi
}

vimrc() {
    say "Install .vimrc..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    fetch dotfile/vim/.vimrc > "$USER_HOME/.vimrc"
}

starship_config() {
    say "Install starship config..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    mkdir -p "$USER_HOME/.config"
    fetch dotfile/starship/starship.toml > "$USER_HOME/.config/starship.toml"
}

# plaesy spec-kit: release binary verified against the release's SHA256SUMS (same logic as plaesy.sh)
plaesy_install() {
    local bin="$PLAESY_DIR/plaesy.exe"
    if have plaesy || [[ -f "$bin" ]]; then
        say "plaesy already installed, skipping."
        return 0
    fi

    say "Install plaesy spec-kit $PLAESY_VERSION..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    local base="https://github.com/plaesy/spec-kit/releases/download/$PLAESY_VERSION"
    local asset="plaesy-windows-amd64.exe" sums expected actual tmp
    sums="$(curl -fsSL "$base/SHA256SUMS" | tr -d '\r')" || die "Could not download SHA256SUMS for $PLAESY_VERSION. Setup stopped."
    expected="$(awk -v name="$asset" '$2 == name { print $1 }' <<< "$sums")"
    [[ -n "$expected" ]] || die "No checksum for $asset in SHA256SUMS. Setup stopped."

    tmp="$(mktemp)"
    curl -fsSL -o "$tmp" "$base/$asset"
    actual="$(sha256sum "$tmp" | cut -d' ' -f1)"
    if [[ "$actual" != "$expected" ]]; then
        rm -f "$tmp"
        die "plaesy checksum mismatch: SHA256SUMS says $expected, got $actual. Setup stopped."
    fi

    mkdir -p "$PLAESY_DIR"
    mv -f "$tmp" "$bin"
    say "plaesy installed."
}

# Windows Developer Mode: needed for FVM's global symlink. Writing HKLM needs admin, so this asks for one UAC prompt
enable_developer_mode() {
    local key='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    local current
    current="$(winps "(Get-ItemProperty -Path '$key' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense")"
    if [[ "$current" == "1" ]]; then
        say "Developer Mode already on, skipping."
        return 0
    fi

    say "Turn on Windows Developer Mode (one admin prompt)..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    local script
    script="$(mktemp --suffix=.ps1)"
    cat > "$script" <<EOF
New-Item -Path '$key' -Force | Out-Null
Set-ItemProperty -Path '$key' -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
EOF
    run_elevated "$script"

    local after
    after="$(winps "(Get-ItemProperty -Path '$key' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense")"
    if [[ "$after" != "1" ]]; then
        warn "Developer Mode is still off. Turn it on in Settings > System > For developers."
    fi
}

# Run a .ps1 file as administrator and wait for it (one UAC prompt)
run_elevated() {
    winps "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File $(cygpath -w "$1")'"
}

# Put folders into the persistent user PATH. flutter.bat calls fvm through cmd, which reads the Windows PATH,
# not the session PATH, so a session-only PATH isn't enough for Flutter.
ensure_user_path() {
    local current new d
    local -a missing=()
    current="$(winps "[Environment]::GetEnvironmentVariable('Path','User')")"
    # mise shims: .exe wrappers for mise-installed CLIs, so GUI apps (FlyEnv) that don't load the shell profile find them
    for d in "$(cygpath -w "$FVM_BIN")" "$(cygpath -w "$PUB_BIN")" "$(cygpath -w "$PLAESY_DIR")" "$(cygpath -w "$MISE_SHIMS")"; do
        case ";$current;" in
            *";$d;"*) ;;
            *) missing+=("$d") ;;
        esac
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        say "User PATH already has the Flutter, FVM, plaesy and mise folders, skipping."
        return 0
    fi

    say "Add Flutter, FVM, plaesy and mise folders to the user PATH..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    new="$current"
    for d in "${missing[@]}"; do
        new="${new:+$new;}$d"
    done
    winps "[Environment]::SetEnvironmentVariable('Path', '$new', 'User')"
}

# Flutter stable through FVM (same steps as flutter.sh). FVM runs on Dart from mise, so Dart's bin goes on PATH
flutter_setup() {
    say "Install Flutter stable via FVM..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    local dart_bin
    dart_bin="$(cygpath -u "$(mise where dart | tr -d '\r')")/bin"
    export PATH="$dart_bin:$PUB_BIN:$PATH"
    fvm install stable
    # `fvm global` makes a symlink, which needs Developer Mode or an elevated shell on Windows.
    # Don't stop the whole setup for that; the message below says what to do.
    if ! fvm global stable; then
        warn "'fvm global stable' failed. Turn on Windows Developer Mode, then run it again."
    fi
}

# Android SDK without Android Studio: command-line tools, then the packages Flutter needs
android_sdk() {
    local sdk="$LOCAL_APP/Android/Sdk"
    local sdkmanager="$sdk/cmdline-tools/latest/bin/sdkmanager.bat"
    say "Install Android SDK (command-line tools, no Android Studio)..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    if [[ ! -f "$sdkmanager" ]]; then
        local zip="$TEMP_DIR/android-cmdline-tools.zip" tmp="$TEMP_DIR/android-cmdline-tools"
        curl -fsSL -o "$zip" "$ANDROID_CMDLINE_ZIP"
        rm -rf "$tmp"
        mkdir -p "$tmp"
        winps "Expand-Archive -Path '$(cygpath -w "$zip")' -DestinationPath '$(cygpath -w "$tmp")' -Force"
        # sdkmanager must sit at <sdk>/cmdline-tools/latest/bin, or flutter doctor reports the component missing
        mkdir -p "$sdk/cmdline-tools"
        rm -rf "$sdk/cmdline-tools/latest"
        mv "$tmp/cmdline-tools" "$sdk/cmdline-tools/latest"
        rm -f "$zip"
    fi

    export JAVA_HOME
    JAVA_HOME="$(cygpath -u "$(mise where java | tr -d '\r')")"
    export ANDROID_HOME="$sdk"
    local sdk_win android
    sdk_win="$(cygpath -w "$sdk")"
    android="$sdk/cmdline-tools/latest/bin/android.exe"
    # sdkmanager is deprecated and hands off to the Android CLI (android.exe). The first run downloads it.
    if [[ ! -f "$android" ]]; then
        cmd.exe //c "$(cygpath -w "$sdkmanager")" --version >/dev/null
    fi
    # Accept every license prompt (60 "y" answers). The pipe can get SIGPIPE once android exits, which
    # pipefail would treat as a failure; a real failure shows up in the flutter config step below.
    # android.exe looks up git and where.exe on PATH, so give it the Windows PATH, not Git Bash's
    local win_path
    # The registry PATH holds %SystemRoot% unexpanded, so expand it, and put System32 first for where.exe
    win_path="$(winps "\"\$env:SystemRoot\\System32;\$env:SystemRoot;\" + [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User'))")"
    printf 'y\n%.0s' {1..60} | PATH="$win_path" "$android" "--sdk=$sdk_win" sdk install "${ANDROID_PACKAGES[@]}" || true
    fvm flutter config --android-sdk "$sdk_win"
}

# Path of the Visual Studio instance that has a component, or empty when none does
vs_find() {
    local progx86 vswhere
    progx86="$(cygpath -u "$(printenv 'ProgramFiles(x86)')")"
    vswhere="$progx86/Microsoft Visual Studio/Installer/vswhere.exe"
    [[ -f "$vswhere" ]] || return 0
    "$vswhere" -products '*' -requires "$1" -latest -property installationPath | tr -d '\r'
}

# Visual Studio Build Tools 2022: C++ workload (MSVC) and C++ ATL for latest v143 build tools. No IDE;
# needed for Flutter Windows desktop and node-gyp. Installing needs admin, so this asks for one UAC prompt.
vs_build_tools() {
    local vs_path atl_path script
    vs_path="$(vs_find "$VS_CPP")"
    atl_path="$(vs_find "$VS_ATL")"
    if [[ -n "$vs_path" && -n "$atl_path" ]]; then
        say "Visual Studio Build Tools (C++ and ATL) already installed, skipping."
        return 0
    fi

    script="$(mktemp --suffix=.ps1)"
    if [[ -n "$vs_path" ]]; then
        # Build Tools is already installed without ATL, so add ATL to that instance
        say "Add C++ ATL for latest v143 build tools to Visual Studio Build Tools (one admin prompt)..."
        if [[ $DRY -eq 1 ]]; then return 0; fi
        local progx86 setup
        progx86="$(cygpath -u "$(printenv 'ProgramFiles(x86)')")"
        setup="$(cygpath -w "$progx86/Microsoft Visual Studio/Installer/setup.exe")"
        printf "& '%s' modify --installPath '%s' --add %s --quiet --norestart\n" "$setup" "$vs_path" "$VS_ATL" > "$script"
    else
        say "Install Visual Studio Build Tools (C++ workload and ATL, one admin prompt)..."
        if [[ $DRY -eq 1 ]]; then return 0; fi
        cat > "$script" <<'EOF'
winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --silent --accept-package-agreements --accept-source-agreements --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.ATL --includeRecommended"
EOF
    fi
    run_elevated "$script"

    if [[ -z "$(vs_find "$VS_CPP")" || -z "$(vs_find "$VS_ATL")" ]]; then
        warn "Visual Studio Build Tools (C++ and ATL) not fully detected. Run the setup again or check the Visual Studio Installer."
    fi
}

# Claude Code via Anthropic's native installer (https://claude.ai/install.ps1). Installs to ~/.local/bin
claude_install() {
    local bin="$USER_HOME/.local/bin/claude.exe"
    if have claude || [[ -f "$bin" ]]; then
        say "Claude Code already installed, skipping."
        return 0
    fi

    say "Install Claude Code..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    winps "iex (irm https://claude.ai/install.ps1)"
    [[ -f "$bin" ]] || warn "Claude Code install failed."
}

# Bash config from dotfile/bash, and VS Code terminal set to Git Bash (same as bash.sh on macOS and Linux)
bash_config() {
    local dir="$USER_HOME/.config/bash"
    say "Install bash config..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    mkdir -p "$dir"
    fetch dotfile/bash/common.sh > "$dir/common.sh"
    fetch dotfile/bash/os-windows.sh > "$dir/os-windows.sh"

    # Keep an existing ~/.bashrc once as ~/.bashrc.bak before it is replaced
    local rc="$USER_HOME/.bashrc" tmp
    tmp="$(mktemp)"
    fetch dotfile/bash/bashrc > "$tmp"
    if [[ -f "$rc" ]] && ! cmp -s "$rc" "$tmp"; then
        cp "$rc" "$rc.bak"
        say "Existing ~/.bashrc saved as ~/.bashrc.bak"
    fi
    mv -f "$tmp" "$rc"

    say "Set Git Bash as the VS Code terminal..."
    local script settings theme
    script="$(mktemp)"
    theme="$(mktemp)"
    fetch dotfile/bash/vscode-terminal.js > "$script"
    fetch dotfile/terminal/theme.json > "$theme"
    settings="$(cygpath -w "$APPDATA")\\Code\\User\\settings.json"
    mise exec -- node "$(cygpath -w "$script")" "$settings" windows 'C:\Program Files\Git\bin\bash.exe' "$(cygpath -w "$theme")"
    rm -f "$script" "$theme"
}

# mise in the PowerShell profile, so node/npm work in a new PowerShell window (mise's PATH is set by activation).
# Windows PowerShell 5.1 is the one that matters here; the block is marked so a re-run replaces nothing.
powershell_profile() {
    say "Add mise to the PowerShell profile..."
    if [[ $DRY -eq 1 ]]; then return 0; fi

    local profile
    profile="$(cygpath -u "$(winps '$PROFILE')")"
    mkdir -p "$(dirname "$profile")"
    touch "$profile"
    if grep -q '^# >>> mise (setup repo)' "$profile"; then
        say "PowerShell profile already has mise, skipping."
        return 0
    fi
    cat >> "$profile" <<'EOF'

# >>> mise (setup repo)
$env:MISE_PWSH_CHPWD_WARNING = 0
if (Get-Command mise -ErrorAction SilentlyContinue) { mise activate pwsh | Out-String | Invoke-Expression }
# <<< mise (setup repo)
EOF
}

# Windows Terminal: Git Bash as the default profile, and the Setup Dark color scheme
windows_terminal_default() {
    local file="$LOCAL_APP/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    if [[ ! -f "$file" ]]; then
        say "Windows Terminal settings not found (open Windows Terminal once), skipping."
        return 0
    fi

    say "Set Windows Terminal to Git Bash with the Setup Dark color scheme..."
    if [[ $DRY -eq 1 ]]; then return 0; fi
    local script theme
    script="$(mktemp)"
    theme="$(mktemp)"
    fetch dotfile/bash/windows-terminal.js > "$script"
    fetch dotfile/terminal/theme.json > "$theme"
    mise exec -- node "$script" "$(cygpath -w "$file")" "$(cygpath -w "$theme")"
    rm -f "$script" "$theme"
}

main() {
    if ! have winget; then
        die "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
    fi

    echo "Windows setup (bash)"
    echo "===================="

    local pkg
    for pkg in "${PACKAGES[@]}"; do
        winget_install ${pkg% *} "${pkg#* }"
    done
    ensure_hermes
    mise_tools
    find_skills
    git_config
    vimrc
    starship_config
    plaesy_install
    claude_install
    enable_developer_mode
    flutter_setup
    ensure_user_path
    android_sdk
    vs_build_tools
    bash_config
    powershell_profile
    windows_terminal_default

    echo
    echo "Setup complete! Open a new Git Bash window, then run: gh auth login"
}

main "$@"
