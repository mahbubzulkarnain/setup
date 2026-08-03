#!/usr/bin/env bash
set -euo pipefail

install_gh_from_release() {
    local os_name="$1" arch_name="$2" archive_ext="$3"

    if command -v gh &>/dev/null; then
        echo "gh already installed, skipping."
        return
    fi

    echo "Install GitHub CLI (gh)..."
    set +o pipefail
    gh_version=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -m1 -oE '"tag_name": *"v[^"]+"' | grep -oE '[0-9.]+')
    set -o pipefail

    local tmp_archive tmp_dir
    tmp_archive=$(mktemp)
    tmp_dir=$(mktemp -d)

    echo "Downloading gh v${gh_version} for ${os_name}_${arch_name}..."
    curl -fsSL -o "$tmp_archive" "https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_${os_name}_${arch_name}.${archive_ext}"

    if [[ "$archive_ext" == "zip" ]]; then
        unzip -q -o "$tmp_archive" -d "$tmp_dir"
    else
        tar -xzf "$tmp_archive" -C "$tmp_dir"
    fi

    local gh_binary
    # Look for gh or gh.exe, handling both root and bin/ subdirectory
    if [[ -f "$tmp_dir/bin/gh.exe" ]]; then
        gh_binary="$tmp_dir/bin/gh.exe"
    elif [[ -f "$tmp_dir/bin/gh" ]]; then
        gh_binary="$tmp_dir/bin/gh"
    elif [[ -f "$tmp_dir/gh.exe" ]]; then
        gh_binary="$tmp_dir/gh.exe"
    elif [[ -f "$tmp_dir/gh" ]]; then
        gh_binary="$tmp_dir/gh"
    else
        echo "Error: gh binary not found in archive"
        echo "Archive contents:"
        find "$tmp_dir" -type f
        rm -rf "$tmp_archive" "$tmp_dir"
        return 1
    fi

    if [[ "$os_name" == "windows" ]]; then
        # For Windows, copy to /usr/bin directly
        cp "$gh_binary" /usr/bin/gh.exe
        echo "gh installed successfully to /usr/bin/gh.exe"
    else
        # For Unix-like systems, use sudo
        sudo install -m 755 "$gh_binary" /usr/local/bin/gh
        echo "gh installed successfully to /usr/local/bin/gh"
    fi
    rm -rf "$tmp_archive" "$tmp_dir"
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
        if brew list gh &>/dev/null; then
            echo "gh already installed, skipping."
        else
            echo "Install gh..."
            brew install gh
        fi
    else
        echo "Homebrew not found, installing gh from release..."
        install_gh_from_release Darwin arm64 tar.gz
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v gh &>/dev/null; then
        echo "gh already installed, skipping."
    else
        echo "Install gh..."
        if command -v apt-get &>/dev/null; then
            # Debian/Ubuntu: add GitHub CLI official repository
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y gh
        else
            # For other Linux distros, download from release
            case "$(dpkg --print-architecture)" in
                amd64) gh_arch="amd64" ;;
                arm64) gh_arch="arm64" ;;
                armhf) gh_arch="armv6" ;;
                *) gh_arch="$(dpkg --print-architecture)" ;;
            esac
            install_gh_from_release linux "$gh_arch" tar.gz
        fi
    fi

elif [[ -n "${MSYSTEM:-}" ]]; then
    if command -v gh &>/dev/null; then
        echo "gh already installed, skipping."
    else
        echo "Install gh..."
        install_gh_from_release windows amd64 zip
    fi

else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install GitHub CLI manually." >&2
    exit 1
fi
