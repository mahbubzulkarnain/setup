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
    pacman -Sy --noconfirm unzip ripgrep fd bat
    install_lazygit_from_release Windows x86_64 zip lazygit.exe /usr/bin

else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install manually or add support for it." >&2
    exit 1
fi
