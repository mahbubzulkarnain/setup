#!/usr/bin/env bash
set -euo pipefail

if command -v gh &>/dev/null; then
    echo "gh already installed, skipping."
    exit 0
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &>/dev/null; then
        echo "Install gh via Homebrew..."
        brew install gh
    else
        echo "Error: Homebrew not found. Please install Homebrew first." >&2
        exit 1
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "Install gh..."
    if command -v apt-get &>/dev/null; then
        # Debian/Ubuntu
        echo "Setting up GitHub CLI repository for Debian/Ubuntu..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    elif command -v pacman &>/dev/null; then
        # Arch Linux
        echo "Installing gh via pacman for Arch Linux..."
        sudo pacman -Sy --noconfirm community/github-cli
    elif command -v dnf &>/dev/null; then
        # Fedora/CentOS/RHEL
        echo "Installing gh via dnf for Fedora/CentOS/RHEL..."
        sudo dnf install -y gh
    elif command -v yum &>/dev/null; then
        # Older Red Hat based systems
        echo "Installing gh via yum..."
        sudo yum install -y gh
    else
        echo "Error: Unsupported Linux distribution. Please install GitHub CLI manually." >&2
        echo "See: https://cli.github.com/manual/installation" >&2
        exit 1
    fi

elif [[ -n "${MSYSTEM:-}" ]]; then
    # Windows (MSYS2)
    echo "Install gh for Windows (MSYS2)..."

    # Try pacman first if available
    if command -v pacman &>/dev/null; then
        echo "Installing via pacman..."
        gh_package="mingw-w64-x86_64-github-cli"
        if [[ "$MSYSTEM" == "MINGW32" ]]; then
            gh_package="mingw-w64-i686-github-cli"
        fi
        pacman -Sy --noconfirm "$gh_package"
    else
        # Fallback: direct download from GitHub releases
        echo "pacman not available, downloading from GitHub releases..."
        set +o pipefail
        gh_version=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep -m1 '"tag_name"' | grep -o 'v[0-9.]*' | sed 's/v//')
        set -o pipefail

        if [[ -z "$gh_version" ]]; then
            echo "Error: Could not determine GitHub CLI version" >&2
            exit 1
        fi

        tmp_dir=$(mktemp -d)
        trap "rm -rf $tmp_dir" EXIT

        echo "Downloading gh v${gh_version}..."
        curl -fsSL -o "$tmp_dir/gh.zip" "https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_windows_amd64.zip"

        echo "Extracting..."
        unzip -q -o "$tmp_dir/gh.zip" -d "$tmp_dir"

        if [[ -f "$tmp_dir/bin/gh.exe" ]]; then
            # Find a writable location in PATH
            install_dir=""
            for dir in /usr/local/bin /usr/bin ~/bin ~/.local/bin "$HOME/bin" /c/msys64/home/CODE.ID/bin; do
                if [[ -d "$dir" ]] && touch "$dir/.test" 2>/dev/null; then
                    rm -f "$dir/.test"
                    install_dir="$dir"
                    break
                elif [[ ! -d "$dir" ]] && mkdir -p "$dir" 2>/dev/null; then
                    install_dir="$dir"
                    break
                fi
            done

            if [[ -z "$install_dir" ]]; then
                echo "Error: Could not find writable directory in PATH" >&2
                echo "Please manually copy $tmp_dir/bin/gh.exe to a directory in your PATH" >&2
                exit 1
            fi

            cp "$tmp_dir/bin/gh.exe" "$install_dir/gh.exe"
            echo "GitHub CLI installed to $install_dir/gh.exe"

            # Also try to install for Windows native (PowerShell)
            if command -v powershell.exe &>/dev/null; then
                echo ""
                echo "To also install gh for Windows native (PowerShell), run:"
                echo "  powershell -Command 'irm https://cli.github.com/install.ps1 | iex'"
                echo "Or if you have scoop/choco/winget, use those instead."
            fi
        else
            echo "Error: gh.exe not found in archive" >&2
            exit 1
        fi
    fi

else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install GitHub CLI manually." >&2
    echo "See: https://cli.github.com/manual/installation" >&2
    exit 1
fi

echo "GitHub CLI (gh) installed successfully!"
