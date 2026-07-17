#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
	OS_TYPE="unknown"
	if [[ "$(uname -s)" == "Darwin" ]]; then
		OS_TYPE="mac"
	elif grep -qi microsoft /proc/version 2>/dev/null; then
		OS_TYPE="wsl"
	elif [[ "$(uname -s)" == "Linux" ]]; then
		OS_TYPE="linux"
		# Check for specific distro
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
				OS_TYPE="debian"
			fi
		fi
	elif [[ "$(uname -s)" =~ (CYGWIN|MINGW|MSYS) ]]; then
		OS_TYPE="windows"
	fi
	echo $OS_TYPE
}

PLATFORM=$(detect_platform)
echo "Detected platform: $PLATFORM"

case "$PLATFORM" in
	debian|wsl)
		if command -v docker &>/dev/null; then
			echo "Docker already installed, skipping."
		else
			echo "Installing Docker for Debian/Ubuntu/WSL..."
			sudo apt-get remove -y docker docker-engine docker.io containerd runc ca-certificates curl gnupg lsb-release
			sudo install -m 0755 -d /etc/apt/keyrings
			curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
			echo \
				"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
				$(lsb_release -cs) stable" | \
				sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
			sudo apt-get update
			sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
			echo "Add user to docker group..."
			sudo usermod -aG docker "$USER"
		fi
		;;
	mac)
		if ! command -v brew &>/dev/null; then
			echo "Homebrew not found. Please install Homebrew first."
			exit 1
		fi
		if brew list --cask docker &>/dev/null; then
			echo "Docker already installed, skipping."
		else
			echo "Installing Docker for MacOS..."
			brew install --cask docker
		fi
		;;
	windows)
		echo "Windows detected. Please install Docker Desktop manually or use winget/Chocolatey:"
		echo "winget install --id Docker.DockerDesktop -e"
		echo "choco install docker-desktop"
		;;
	linux)
		echo "Automatic Docker install not supported for this Linux distro yet. Follow https://docs.docker.com/engine/install/ for your distro." >&2
		;;
	*)
		echo "Unknown or unsupported platform. Please install Docker manually." >&2
		;;
esac