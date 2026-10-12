#!/usr/bin/env nu
# Windows setup (Nushell)
# Usage: nu windows.nu [--dry-run]
#
# Nushell counterpart of windows.sh. Installs with winget, skips anything
# already installed, and applies the same config as the other scripts.

const RAW = "https://raw.githubusercontent.com/mahbubzulkarnain/setup/master"

# winget package id -> command used to check whether it is already installed
const PACKAGES = [
    { id: "Git.Git", cmd: "git" }
    { id: "GitHub.cli", cmd: "gh" }
    { id: "BurntSushi.ripgrep.MSVC", cmd: "rg" }
    { id: "sharkdp.fd", cmd: "fd" }
    { id: "sharkdp.bat", cmd: "bat" }
    { id: "JesseDuffield.lazygit", cmd: "lazygit" }
    { id: "jdx.mise", cmd: "mise" }
    { id: "Starship.Starship", cmd: "starship" }
    { id: "ajeetdsouza.zoxide", cmd: "zoxide" }
    { id: "junegunn.fzf", cmd: "fzf" }
    { id: "ezwinports.make", cmd: "make" }
    { id: "vim.vim", cmd: "vim" }
]

# Config file from this repo when run inside it, otherwise from GitHub master
def fetch [rel: string] {
    let local = ($env.PWD | path join $rel)
    if ($local | path exists) { open --raw $local } else { http get $"($RAW)/($rel)" }
}

# Reload PATH from the registry so tools installed earlier in this run are found
def --env refresh-path [] {
    let machine = (^powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path', 'Machine')" | str trim)
    let user = (^powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path', 'User')" | str trim)
    $env.PATH = ($env.PATH | append ([$machine $user] | str join ';' | split row ';' | where {|p| $p != '' }) | uniq)
}

def --env winget-install [pkg: record, dry: bool] {
    if (which $pkg.cmd | is-not-empty) {
        print $"($pkg.cmd) already installed, skipping."
        return
    }

    print $"Install ($pkg.id)..."
    if $dry { return }

    ^winget install --id $pkg.id --exact --silent --accept-package-agreements --accept-source-agreements
    if $env.LAST_EXIT_CODE != 0 {
        print -e $"Warning: winget exited with ($env.LAST_EXIT_CODE) for ($pkg.id)"
    }
    refresh-path
}

# Same check as ai.sh
def ensure-hermes [dry: bool] {
    if ($env.LOCALAPPDATA | path join 'hermes' | path exists) {
        print "Hermes Agent already installed, skipping."
        return
    }

    print "Install Hermes Agent..."
    if $dry { return }

    ^powershell -NoProfile -Command "iex (irm https://hermes-agent.nousresearch.com/install.ps1)"
}

# Node.js, Go, Python, and global CLIs from dotfile/mise/config.toml (same file mise.sh uses)
def mise-tools [dry: bool] {
    let config_dir = ($env.USERPROFILE | path join '.config' 'mise')
    print "Install mise tools (node, go, python, global CLIs)..."
    if not $dry {
        mkdir $config_dir
        let config = ($config_dir | path join 'config.toml')
        fetch "dotfile/mise/config.toml" | save -f $config
        ^mise install
        # Kilo CLI follows "latest", so move it to the newest release on every run
        ^mise upgrade "npm:@kilocode/cli"
        # FVM (Flutter version manager) via Dart from mise
        ^mise exec -- dart pub global activate fvm
    }
}

def git-config [dry: bool] {
    if (which git | is-empty) {
        print -e "git not found, skipping git config."
        return
    }

    let ignore_file = ($env.USERPROFILE | path join '.gitignore_global' | str replace --all '\' '/')
    let current_ignore = (^git config --global --get core.excludesfile | complete | get stdout | str trim)
    if $current_ignore != $ignore_file {
        print "Setting up Git global..."
        if not $dry {
            fetch "dotfile/gitignore/.gitignore_global" | save -f $ignore_file
            ^git config --global core.excludesfile $ignore_file
        }
    }

    let current_name = (^git config --global --get user.name | complete | get stdout | str trim)
    if $current_name != "Mahbub Zulkarnain" {
        print "Setting up Git user.name..."
        if not $dry {
            ^git config --global user.name "Mahbub Zulkarnain"
        }
    }
}

def vimrc [dry: bool] {
    print "Install .vimrc..."
    if not $dry {
        fetch "dotfile/vim/.vimrc" | save -f ($env.USERPROFILE | path join '.vimrc')
    }
}

# plaesy spec-kit: pinned release binary, checked against its SHA-256 (same values as plaesy.sh)
const PLAESY_VERSION = "v0.0.1"
const PLAESY_SHA256 = "c1143a00dac0739a127ec86d109406d5c8ea7f1251de5cb69dd31f60cd3af558"

def plaesy-install [dry: bool] {
    let plaesy_dir = ($env.LOCALAPPDATA | path join "Plaesy" "bin")
    let plaesy_bin = ($plaesy_dir | path join "plaesy.exe")
    if ((which plaesy | is-not-empty) or ($plaesy_bin | path exists)) {
        print "plaesy already installed, skipping."
        return
    }

    print $"Install plaesy spec-kit ($PLAESY_VERSION)..."
    if $dry { return }

    let tmp = ($env.TEMP | path join "plaesy-download.exe")
    let url = $"https://github.com/plaesy/spec-kit/releases/download/($PLAESY_VERSION)/plaesy-windows-amd64.exe"
    ^curl.exe -fsSL -o $tmp $url

    let actual = (open --raw $tmp | hash sha256)
    if $actual != $PLAESY_SHA256 {
        rm -f $tmp
        error make { msg: $"plaesy checksum mismatch: expected ($PLAESY_SHA256), got ($actual). Setup stopped." }
    }

    mkdir $plaesy_dir
    mv -f $tmp $plaesy_bin
    print "plaesy installed."
}

# Windows Developer Mode: needed for FVM's global symlink. Writing HKLM needs admin, so this asks for one UAC prompt
def enable-developer-mode [dry: bool] {
    let key = r#'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'#
    let current = (^powershell -NoProfile -Command $"\(Get-ItemProperty -Path '($key)' -ErrorAction SilentlyContinue\).AllowDevelopmentWithoutDevLicense" | str trim)
    if $current == "1" {
        print "Developer Mode already on, skipping."
        return
    }

    print "Turn on Windows Developer Mode (one admin prompt)..."
    if $dry { return }

    let script = ($env.TEMP | path join "enable-devmode.ps1")
    r#'New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
'#  | save -f $script
    ^powershell -NoProfile -Command ("Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File " + $script + "'")

    let after = (^powershell -NoProfile -Command $"\(Get-ItemProperty -Path '($key)' -ErrorAction SilentlyContinue\).AllowDevelopmentWithoutDevLicense" | str trim)
    if $after != "1" {
        print -e "Warning: Developer Mode is still off. Turn it on in Settings > System > For developers."
    }
}

# Put folders into the persistent user PATH. flutter.bat calls fvm through cmd, which reads the Windows PATH,
# not Nushell's $env.PATH, so a session-only PATH isn't enough for Flutter.
def ensure-user-path [dirs: list<string>, dry: bool] {
    let current = (^powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('Path','User')" | str trim)
    let parts = ($current | split row ';' | where {|p| $p != '' })
    let missing = ($dirs | where {|d| not ($parts | any {|p| $p == $d }) })
    if ($missing | is-empty) {
        print "User PATH already has the Flutter and FVM folders, skipping."
        return
    }

    print "Add Flutter and FVM folders to the user PATH..."
    if $dry { return }
    let new = ($parts | append $missing | str join ';')
    ^powershell -NoProfile -Command ("[Environment]::SetEnvironmentVariable('Path', '" + $new + "', 'User')")
}

# Flutter stable through FVM (same steps as flutter.sh). FVM runs on Dart from mise, so Dart's bin goes on PATH
def flutter-setup [dry: bool] {
    print "Install Flutter stable via FVM..."
    if $dry { return }

    let dart_bin = ((^mise where dart | str trim) | path join "bin")
    let pub_bin = ($env.LOCALAPPDATA | path join "Pub" "Cache" "bin")
    $env.PATH = ($env.PATH | prepend [$dart_bin $pub_bin])
    do {
        ^fvm install stable
        # `fvm global` makes a symlink, which needs Developer Mode or an elevated shell on Windows.
        # Don't stop the whole setup for that; the message below says what to do.
        let global = (do -i { ^fvm global stable } | complete)
        if $global.exit_code != 0 {
            print -e "Warning: `fvm global stable` failed. Turn on Windows Developer Mode, then run it again."
        }
    }
}

# Android SDK without Android Studio: command-line tools, then the packages Flutter needs.
# Source for the zip: Google's repository index (repository2-3.xml), revision current at the time of writing.
const ANDROID_CMDLINE_ZIP = "https://dl.google.com/android/repository/commandlinetools-win-16111833_latest.zip"
const ANDROID_PACKAGES = ["platform-tools" "platforms/android-36" "build-tools/36.1.0"]

def android-sdk [dry: bool] {
    let sdk = ($env.LOCALAPPDATA | path join "Android" "Sdk")
    let sdkmanager = ($sdk | path join "cmdline-tools" "latest" "bin" "sdkmanager.bat")
    print "Install Android SDK (command-line tools, no Android Studio)..."
    if $dry { return }

    if not ($sdkmanager | path exists) {
        let zip = ($env.TEMP | path join "android-cmdline-tools.zip")
        let tmp = ($env.TEMP | path join "android-cmdline-tools")
        ^curl.exe -fsSL -o $zip $ANDROID_CMDLINE_ZIP
        rm -rf $tmp
        mkdir $tmp
        ^powershell -NoProfile -Command $"Expand-Archive -Path '($zip)' -DestinationPath '($tmp)' -Force"
        # sdkmanager must sit at <sdk>/cmdline-tools/latest/bin, or flutter doctor reports the component missing
        mkdir ($sdk | path join "cmdline-tools")
        rm -rf ($sdk | path join "cmdline-tools" "latest")
        mv ($tmp | path join "cmdline-tools") ($sdk | path join "cmdline-tools" "latest")
        rm -f $zip
    }

    let java_home = (^mise where java | str trim)
    let dart_bin = ((^mise where dart | str trim) | path join "bin")
    let pub_bin = ($env.LOCALAPPDATA | path join "Pub" "Cache" "bin")
    # sdkmanager is deprecated and hands off to the Android CLI (android.exe). The first run downloads it.
    let android = ($sdk | path join "cmdline-tools" "latest" "bin" "android.exe")
    if not ($android | path exists) { ^$sdkmanager --version }
    $env.JAVA_HOME = $java_home
    $env.ANDROID_HOME = $sdk
    # Accept every license prompt
    1..60 | each {|_| "y" } | str join "\n" | ^$android $"--sdk=($sdk)" sdk install ...$ANDROID_PACKAGES
    $env.PATH = ($env.PATH | prepend [$dart_bin $pub_bin])
    ^fvm flutter config --android-sdk $sdk
}

# Visual Studio Build Tools 2022 with the C++ workload (MSVC). No IDE; needed for Flutter Windows desktop and node-gyp.
# Installing needs admin, so this asks for one UAC prompt.
def vs-build-tools [dry: bool] {
    let vswhere = ($env."ProgramFiles(x86)" | path join "Microsoft Visual Studio" "Installer" "vswhere.exe")
    let has_vc = if ($vswhere | path exists) {
        (^$vswhere -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -latest -property installationPath | str trim | is-not-empty)
    } else { false }
    if $has_vc {
        print "Visual Studio Build Tools (C++) already installed, skipping."
        return
    }

    print "Install Visual Studio Build Tools (C++ workload, one admin prompt)..."
    if $dry { return }

    let script = ($env.TEMP | path join "vs-build-tools.ps1")
    r#'winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --silent --accept-package-agreements --accept-source-agreements --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
'#  | save -f $script
    ^powershell -NoProfile -Command ("Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File " + $script + "'")

    let installed = if ($vswhere | path exists) {
        (^$vswhere -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -latest -property installationPath | str trim | is-not-empty)
    } else { false }
    if not $installed {
        print -e "Warning: Visual Studio Build Tools (C++) not detected. Run the install again or check the Visual Studio Installer."
    }
}

# Claude Code via Anthropic's native installer (https://claude.ai/install.ps1). Installs to ~/.local/bin
def claude-install [dry: bool] {
    let claude_bin = ($env.USERPROFILE | path join '.local' 'bin' 'claude.exe')
    if ((which claude | is-not-empty) or ($claude_bin | path exists)) {
        print "Claude Code already installed, skipping."
        return
    }

    print "Install Claude Code..."
    if $dry { return }

    ^powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://claude.ai/install.ps1)"
    if not ($claude_bin | path exists) {
        print -e "Warning: Claude Code install failed."
    }
}

# Starship config (the Nushell init is generated by env.nu on every start)
def starship-config [dry: bool] {
    let config = ($env.USERPROFILE | path join '.config' 'starship.toml')

    print "Install starship config..."
    if not $dry {
        mkdir ($config | path dirname)
        fetch "dotfile/starship/starship.toml" | save -f $config
    }
}

# Nushell config from dotfile/nushell, and VS Code terminal set to nu (same as nushell.sh)
def nu-config [dry: bool] {
    let cfg = $nu.default-config-dir

    print "Install Nushell config..."
    if not $dry {
        mkdir $cfg
        for f in ["env.nu" "config.nu"] {
            fetch $"dotfile/nushell/($f)" | save -f ($cfg | path join $f)
        }
    }

    print "Set Nushell as the VS Code terminal..."
    if not $dry {
        let script = ($env.TEMP | path join "vscode-nu.nu")
        fetch "dotfile/nushell/vscode.nu" | save -f $script
        with-env {
            VSCODE_SETTINGS: ($env.APPDATA | path join "Code" "User" "settings.json")
            VSCODE_OS: "windows"
        } {
            ^nu $script
        }
    }
}

# Windows Terminal: make the Nushell profile the default. The file is JSONC (has comments), so only the
# defaultProfile line is rewritten; the rest of the file is left byte-for-byte as it is.
def windows-terminal-default [dry: bool] {
    let file = ($env.LOCALAPPDATA | path join "Packages" "Microsoft.WindowsTerminal_8wekyb3d8bbwe" "LocalState" "settings.json")
    if not ($file | path exists) {
        print "Windows Terminal settings not found (open Windows Terminal once), skipping."
        return
    }

    let text = (open --raw $file)
    let found = ($text | parse --regex '"guid": "(?<guid>\{[^"]+\})"[^{}]*"name": "Nushell"')
    if ($found | is-empty) {
        print -e "Warning: no Nushell profile in Windows Terminal; default profile unchanged."
        return
    }
    let guid = ($found | first | get guid)

    if ($text | str contains $'"defaultProfile": "($guid)"') {
        print "Windows Terminal default is already Nushell, skipping."
        return
    }

    print "Set Windows Terminal default profile to Nushell..."
    if $dry { return }
    let updated = ($text | str replace -r '"defaultProfile": "\{[^"]+\}"' $'"defaultProfile": "($guid)"')
    $updated | save -f $file
}

def main [--dry-run] {
    let dry = $dry_run

    if $dry { print "Dry run: no changes will be made.\n" }

    if (which winget | is-empty) {
        error make { msg: "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." }
    }

    print "Windows setup (Nushell)"
    print "======================="

    for pkg in $PACKAGES {
        winget-install $pkg $dry
    }
    ensure-hermes $dry
    mise-tools $dry
    git-config $dry
    vimrc $dry
    starship-config $dry
    plaesy-install $dry
    claude-install $dry
    enable-developer-mode $dry
    flutter-setup $dry
    ensure-user-path [($env.USERPROFILE | path join "fvm" "default" "bin") ($env.LOCALAPPDATA | path join "Pub" "Cache" "bin")] $dry
    android-sdk $dry
    vs-build-tools $dry
    nu-config $dry
    windows-terminal-default $dry

    print "\nSetup complete! Open a new terminal, then run: gh auth login"
}
