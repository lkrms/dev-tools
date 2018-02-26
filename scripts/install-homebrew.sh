#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

command -v brew >/dev/null 2>&1 || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 2

brew install \
    coreutils \
    ghostscript \
    mariadb \
    micro \
    node \
    pandoc \
    pv \
    rsync \
    wget \
    youtube-dl \
    || exit 2

brew cask install mactex || exit 2

if [ ! -e /usr/local/bin/pdflatex -a -e /Library/TeX/Root/bin/x86_64-darwin/pdflatex ]; then

    ln -s /Library/TeX/Root/bin/x86_64-darwin/pdflatex /usr/local/bin/pdflatex

fi

# Uncomment if you need to mount ext4 volumes on your Mac:
#brew cask install osxfuse
#brew install ext4fuse

