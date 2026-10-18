#!/usr/bin/env bash
set -euo pipefail

# Flutter stable through FVM (installed by mise.sh), plus the Android SDK without Android Studio.
# Windows: windows.sh does the same steps. Project Flutter versions are pinned per project with `fvm use`.

ANDROID_CMDLINE_REVISION=16111833
ANDROID_PACKAGES=("platform-tools" "platforms/android-36" "build-tools/36.1.0")

export PATH="$HOME/.local/bin:$HOME/.pub-cache/bin:$PATH"
# fvm runs on Dart, which mise manages; mise exec can't run fvm itself, so put Dart's bin on PATH
export PATH="$(mise where dart)/bin:$PATH"

if ! command -v fvm &>/dev/null; then
    echo "Error: fvm not found. Run mise.sh first." >&2
    exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    os_name=mac
    desktop_flag="--enable-macos-desktop"
    android_sdk="$HOME/Library/Android/sdk"
else
    os_name=linux
    desktop_flag="--enable-linux-desktop"
    android_sdk="$HOME/Android/Sdk"
    # Build dependencies for Linux desktop targets
    sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
fi

echo "Install Flutter stable via FVM..."
fvm install stable
fvm global stable
fvm flutter config "$desktop_flag"

echo "Install Android SDK (command-line tools, no Android Studio)..."
sdkmanager="$android_sdk/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$sdkmanager" ]]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL -o "$tmp/cmdline-tools.zip" \
        "https://dl.google.com/android/repository/commandlinetools-${os_name}-${ANDROID_CMDLINE_REVISION}_latest.zip"
    unzip -q "$tmp/cmdline-tools.zip" -d "$tmp"
    # sdkmanager must sit at <sdk>/cmdline-tools/latest/bin, or flutter doctor reports the component missing
    mkdir -p "$android_sdk/cmdline-tools"
    rm -rf "$android_sdk/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "$android_sdk/cmdline-tools/latest"
fi

export JAVA_HOME="$(mise where java)"
export ANDROID_HOME="$android_sdk"
# sdkmanager is deprecated and hands off to the Android CLI (`android`). The first run downloads it.
android="$android_sdk/cmdline-tools/latest/bin/android"
if [[ ! -x "$android" ]]; then
    "$sdkmanager" --version >/dev/null
fi
# Accept every license prompt. `yes` gets SIGPIPE once android exits, which pipefail would treat as a failure;
# a real failure shows up in the install step below.
yes | "$android" --sdk="$android_sdk" sdk install "${ANDROID_PACKAGES[@]}" || true
fvm flutter config --android-sdk "$android_sdk"
