#!/usr/bin/env bash
set -euo pipefail

# Modern CLI tools: ripgrep, fd, bat, lazygit

run_remote() {
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$1" -o "$tmp"
    bash "$tmp"
    rm -f "$tmp"
}

install_exe_from_release_zip() {
    local repo="$1" asset_regex="$2" bin_name="$3"

    if command -v "$bin_name" &>/dev/null; then
        echo "$bin_name already installed, skipping."
        return
    fi

    echo "Install $bin_name..."
    set +o pipefail
    local asset_url
    asset_url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | grep -m1 -oE "https://github\.com/$repo/releases/download/[^\"]*${asset_regex}")
    set -o pipefail

    local tmp_zip tmp_dir
    tmp_zip=$(mktemp)
    tmp_dir=$(mktemp -d)
    curl -fsSL -o "$tmp_zip" "$asset_url"
    unzip -q -o "$tmp_zip" -d "$tmp_dir"

    local exe_path
    exe_path=$(find "$tmp_dir" -iname "${bin_name}.exe" | head -1)
    install -m 755 "$exe_path" "/usr/bin/${bin_name}.exe"
    rm -rf "$tmp_zip" "$tmp_dir"
}

install_lazygit_from_release() {
    local os_name="$1" arch_name="$2" archive_ext="$3" bin_name="$4" install_dir="$5"

    if command -v lazygit &>/dev/null; then
        echo "lazygit already installed, skipping."
        return
    fi

    echo "Install lazygit..."
    set +o pipefail
    lazygit_version=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -m1 -oE '"tag_name": *"v[^"]+"' | grep -oE '[0-9.]+')
    set -o pipefail

    local tmp_archive tmp_dir
    tmp_archive=$(mktemp)
    tmp_dir=$(mktemp -d)
    curl -fsSL -o "$tmp_archive" "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_${os_name}_${arch_name}.${archive_ext}"

    if [[ "$archive_ext" == "zip" ]]; then
        unzip -q -o "$tmp_archive" -d "$tmp_dir"
    else
        tar -xzf "$tmp_archive" -C "$tmp_dir"
    fi
    install -m 755 "$tmp_dir/$bin_name" "$install_dir/$bin_name"
    rm -rf "$tmp_archive" "$tmp_dir"
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
        run_remote https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/brew.sh
    fi

    for pkg in ripgrep fd bat lazygit; do
        if brew list "$pkg" &>/dev/null; then
            echo "$pkg already installed, skipping."
        else
            echo "Install $pkg..."
            brew install "$pkg"
        fi
    done

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Update..."
    sudo apt-get update
    sudo apt-get install -y ripgrep fd-find bat

    mkdir -p ~/.local/bin
    [[ -x ~/.local/bin/fd ]] || ln -sf "$(command -v fdfind)" ~/.local/bin/fd
    [[ -x ~/.local/bin/bat ]] || ln -sf "$(command -v batcat)" ~/.local/bin/bat

    case "$(dpkg --print-architecture)" in
        amd64) lazygit_arch="x86_64" ;;
        arm64) lazygit_arch="arm64" ;;
        *) lazygit_arch="$(dpkg --print-architecture)" ;;
    esac
    install_lazygit_from_release Linux "$lazygit_arch" tar.gz lazygit /usr/local/bin

elif [[ -n "${MSYSTEM:-}" ]]; then
    # ripgrep/fd/bat aren't in the base "msys" pacman repo (only under
    # mingw-w64-* subsystems that aren't on PATH here), so grab the
    # official prebuilt Windows binaries instead, same as lazygit below.
    pacman -Sy --noconfirm unzip
    install_exe_from_release_zip BurntSushi/ripgrep 'ripgrep-[^"]*-x86_64-pc-windows-msvc\.zip' rg
    install_exe_from_release_zip sharkdp/fd 'fd-[^"]*-x86_64-pc-windows-msvc\.zip' fd
    install_exe_from_release_zip sharkdp/bat 'bat-[^"]*-x86_64-pc-windows-msvc\.zip' bat
    install_lazygit_from_release Windows x86_64 zip lazygit.exe /usr/bin

else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install manually or add support for it." >&2
    exit 1
fi
