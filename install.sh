#!/usr/bin/env bash

mkdir -p /usr/local/bin/ && sudo ln -sf ~/.ez-install/ez /usr/local/bin/

if [ "$(uname)" == "Darwin" ]; then
	brew install jq
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	if [ -x "$(command -v apk)" ]; then sudo apk add jq; fi
	if [ -x "$(command -v pkg)" ]; then sudo pkg install jq; fi
	if [ -x "$(command -v pacman)" ]; then sudo pacman -S jq; fi
	if [ -x "$(command -v apt)" ]; then sudo apt install jq; fi
	if [ -x "$(command -v dnf)" ]; then sudo dnf install jq; fi
	if [ -x "$(command -v nix-env)" ]; then sudo nix-env -i jq; fi
	if [ -x "$(command -v zypper)" ]; then sudo zypper install jq; fi
fi
