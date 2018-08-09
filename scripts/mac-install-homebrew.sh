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

read -p "Install developer tools? [y/n] " -n 1 -r INSTALL_DEV_TOOLS

echo

if [[ $INSTALL_DEV_TOOLS =~ ^[Yy]$ ]]; then

    brew install \
        ant \
        autoconf \
        mariadb \
        node \
        nvm \
        yarn \
        || exit 2

fi

read -p "Install TeX? [y/n] " -n 1 -r INSTALL_TEX

echo

if [[ $INSTALL_TEX =~ ^[Yy]$ ]]; then

    brew cask install mactex || exit 2

    if [ ! -e /usr/local/bin/pdflatex -a -e /Library/TeX/Root/bin/x86_64-darwin/pdflatex ]; then

        ln -s /Library/TeX/Root/bin/x86_64-darwin/pdflatex /usr/local/bin/pdflatex

    fi

fi

