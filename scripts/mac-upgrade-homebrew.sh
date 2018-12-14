#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

command -v brew >/dev/null 2>&1 || { echo "Error: Homebrew doesn't appear to be installed."; exit 2; }

echo -e "Attempting Homebrew update/upgrade/cleanup at $(date '+%c')...\n"

brew update
brew upgrade
brew cask upgrade
brew cleanup

[ -e /Library/TeX/texbin/luaotfload-tool ] && /Library/TeX/texbin/luaotfload-tool --update

echo -e "\nOperation completed at: $(date '+%c')"

