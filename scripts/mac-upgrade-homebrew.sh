#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew doesn't appear to be installed."; exit 2; }

echo -e "Attempting Homebrew update/upgrade/cleanup at $(date '+%c')...\n"

brew update
brew upgrade
brew cleanup

echo -e "\nOperation completed at: $(date '+%c')"

