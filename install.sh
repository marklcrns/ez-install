#!/usr/bin/env bash

LOCAL_BIN_DIR="/usr/local/bin"

# Check if already has symlink
if ! [[ -L "${LOCAL_BIN_DIR}/ez" ]]; then
	echo "Creating symlink to ${LOCAL_BIN_DIR}/ez..."
	mkdir -p "${LOCAL_BIN_DIR}" && sudo ln -sf ~/.ez-install/ez "${LOCAL_BIN_DIR}"
fi

unameOut="$(uname -s)"
case "${unameOut}" in
Linux*) machine=Linux ;;
Darwin*) machine=Mac ;;
CYGWIN*) machine=Cygwin ;;
MINGW*) machine=MinGw ;;
*) machine="UNKNOWN:${unameOut}" ;;
esac

# Install JQ if not existing
if ! command -v jq &>/dev/null; then
	if [ "$machine" == "Mac" ]; then
		brew install jq
	elif [ "$machine" == "Linux" ]; then
		if command -v apk &>/dev/null; then
			sudo apk add jq
		elif command -v pkg &>/dev/null; then
			sudo pkg install jq
		elif command -v pacman &>/dev/null; then
			sudo pacman -S jq
		elif command -v apt &>/dev/null; then
			sudo apt install jq
		elif command -v dnf &>/dev/null; then
			sudo dnf install jq
		elif command -v zypper &>/dev/null; then
			sudo zypper install jq
		elif command -v nix-env &>/dev/null; then
			sudo nix-env -i jq
		fi
	fi
fi

echo "Generating packages..."
"$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"/scripts/generate-packages
echo "Installation done!"
