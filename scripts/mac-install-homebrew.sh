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

# ghostscript: PDF/PostScript processor
# imagemagick: image processor
# pandoc: text conversion tool (e.g. Markdown to PDF)
# poppler: PDF tools like pdfimages
# python3: so that we can use pip3 below
brew install \
    coreutils \
    exiftool \
    ghostscript \
    imagemagick \
    lftp \
    pandoc \
    poppler \
    pv \
    python3 \
    rsync \
    telnet \
    wget \
    youtube-dl \
    || exit 2

# img2pdf: lossless creation of PDFs from source JPEGs
pip3 install -U \
    img2pdf \
    || exit 2

read -p "Install OCR tools (including tesseract-lang)? [y/n] " -n 1 -r INSTALL_OCR_TOOLS

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

OLD_NVM_DIR="$NVM_DIR"

if [[ $INSTALL_DEV_TOOLS =~ ^[Yy]$ ]]; then

    brew install \
        ant \
        autoconf \
        cmake \
        composer \
        gradle \
        mariadb \
        msmtp \
        php@7.2 \
        pkg-config \
        || exit 2

    # don't disturb an existing nvm installation
    if [ -z "$OLD_NVM_DIR" -o "$OLD_NVM_DIR" = "$HOME/.nvm" ]; then

        export NVM_DIR="$HOME/.nvm"

        if [ ! -e "$NVM_DIR" ]; then

            git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" || exit 2
            pushd "$NVM_DIR" >/dev/null || exit 2
            git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)) || exit 2
            popd >/dev/null

            . "$NVM_DIR/nvm.sh" || exit 2

            NVM_INSTALLED=1

        elif [ -d "$NVM_DIR/.git" ]; then

            pushd "$NVM_DIR" >/dev/null || exit 2
            git fetch --tags origin
            git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)) || exit 2
            popd >/dev/null

            . "$NVM_DIR/nvm.sh" || exit 2

        fi

    fi

    nvm install 8 || exit 2

    # work around Homebrew's reluctance to recognise nvm-based node by installing Yarn like this...
    npm install -g \
        eslint \
        yarn \
        || exit 2

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

if [ -z "$OLD_NVM_DIR" -a -n "$NVM_DIR" ]; then

    echo -e "\n\nIMPORTANT: nvm is installed, so you need something like this in your "'~/.profile'":\n"
    echo '[ -e "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm" && [ -e "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

fi

