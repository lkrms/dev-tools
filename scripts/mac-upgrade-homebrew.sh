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

command -v npm >/dev/null 2>&1 && { npm --depth 9999 update; npm --depth 9999 update -g; }

[ -e /Library/TeX/texbin/luaotfload-tool ] && /Library/TeX/texbin/luaotfload-tool --update
command -v tlmgr >/dev/null 2>&1 && sudo tlmgr update --self

echo -e "\nOperation completed at: $(date '+%c')"

