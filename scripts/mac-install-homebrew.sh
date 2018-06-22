#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

command -v brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 2

brew upgrade

brew install \
    coreutils \
    ghostscript \
    micro \
    pandoc \
    pv \
    rsync \
    wget \
    youtube-dl \
    || exit 2

echo -e "\n\nDone. If you need to mount ext4 volumes on your Mac, please also run: brew cask install osxfuse && brew install ext4fuse"

