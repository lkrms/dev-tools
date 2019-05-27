#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

if command -v brew >/dev/null 2>&1; then

    brew upgrade
    brew cask upgrade

else

    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 2

fi

brew install \
    coreutils \
    exiftool \
    ghostscript \
    gnupg \
    lftp \
    pandoc \
    poppler \
    pv \
    rsync \
    telnet \
    wget \
    youtube-dl \
    || exit 2

read -p "Install OCR tools? [y/n] " -n 1 -r INSTALL_OCR_TOOLS

echo

if [[ $INSTALL_OCR_TOOLS =~ ^[Yy]$ ]]; then

    brew install \
        ocrmypdf \
        tesseract \
        tesseract-lang \
        || exit 2


fi

read -p "Install developer tools? [y/n] " -n 1 -r INSTALL_DEV_TOOLS

echo

if [[ $INSTALL_DEV_TOOLS =~ ^[Yy]$ ]]; then

    brew install \
        ant \
        autoconf \
        cmake \
        composer \
        gradle \
        mariadb \
        msmtp \
        nvm \
        php@7.1 \
        pkg-config \
        yarn \
        || exit 2

    mkdir -p "$HOME/.nvm" || exit 2
    export NVM_DIR="$HOME/.nvm"
    . "$(brew --prefix nvm)/nvm.sh" || exit 2
    nvm install 8 || exit 2

    npm install -g eslint

fi

read -p "Install PowerShell? [y/n] " -n 1 -r INSTALL_POWERSHELL

echo

if [[ $INSTALL_POWERSHELL =~ ^[Yy]$ ]]; then

    brew cask install powershell || exit 2

fi

read -p "Install BasicTeX? [y/n] " -n 1 -r INSTALL_TEX

echo

if [[ $INSTALL_TEX =~ ^[Yy]$ ]]; then

    brew cask install basictex || exit 2
    sudo tlmgr update --self && sudo tlmgr install collection-fontsrecommended || exit 2
    luaotfload-tool --update || exit 2

fi

