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
    if command -v choco &>/dev/null; then
        echo "Install gh via Chocolatey..."
        choco install gh -y
    else
        echo "Error: Chocolatey not found. Please install Chocolatey first." >&2
        echo "See: https://chocolatey.org/install" >&2
        exit 1
    fi

else
    echo "Unsupported/unrecognized OS (OSTYPE=$OSTYPE). Please install GitHub CLI manually." >&2
    echo "See: https://cli.github.com/manual/installation" >&2
    exit 1
fi

echo "GitHub CLI (gh) installed successfully!"
