#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") </path/to/app/folder>"
    exit 1

fi

if [ ! -d "$1" ]; then

    echo "Error: $1 doesn't exist or isn't a folder."
    exit 2

fi

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
MOUNT_ROOT="$HOME/install.mount"

mkdir -p "$MOUNT_ROOT/zip" || exit 2

function main_loop {

    # extract any zip files
    find "$1" -maxdepth 1 -iname '*.zip' -type f -print0 | while read -d $'\0' ZIP; do

        ZIP_NAME="$(basename "$ZIP")"

        echo "Extracting $ZIP_NAME..."
        unzip -q "$ZIP" -d "$MOUNT_ROOT/zip/" || exit 2

        echo "Done extracting $ZIP_NAME."

    done

    # extract any tar files
    find "$1" -maxdepth 1 \( -iname '*.tar' -o -iname '*.tar.*' \) -type f -print0 | while read -d $'\0' TAR; do

        TAR_NAME="$(basename "$TAR")"

        echo "Extracting $TAR_NAME..."
        tar -xf "$TAR" -C "$MOUNT_ROOT/zip/" || exit 2

        echo "Done extracting $TAR_NAME."

    done

    # mount any disk images
    find "$1" -maxdepth 1 -iname '*.dmg' -type f -exec hdiutil attach -mountroot "$MOUNT_ROOT" '{}' \;

    # look for .apps to install
    find "$MOUNT_ROOT" -mindepth 2 -maxdepth 2 -iname '*.app' -type d -print0 | while read -d $'\0' APP; do

        APP_NAME="$(basename "$APP")"

        if [ -e "/Applications/$APP_NAME" ]; then

            echo "$APP_NAME is already installed. Skipping."
            continue

        fi

        echo "Installing $APP_NAME..."
        sudo cp -Rp "$APP" /Applications/

        echo "Done installing $APP_NAME."

    done

    # .pkgs too
    install_pkgs "$MOUNT_ROOT" 2

    # unmount
    find "$MOUNT_ROOT" -type d -mindepth 1 -maxdepth 1 ! -iname zip -exec hdiutil unmount '{}' \;

    # clean up extracted zip files
    rm -Rf "$MOUNT_ROOT/zip"/*

    # install packages in this folder
    install_pkgs "$1" 1

}

function install_pkgs {

    find "$1" -mindepth $2 -maxdepth $2 -iname '*.pkg' -type f -print0 | while read -d $'\0' PKG; do

        PKG_NAME="$(basename "$PKG")"

        echo "Installing $PKG_NAME..."
        sudo installer -allowUntrusted -pkg "$PKG" -target /

        RESULT=$?

        echo "Done installing $PKG_NAME (exit code $RESULT)."

    done

}

main_loop "$1"

rm -Rf "$MOUNT_ROOT"

echo "Lifting quarantine on downloaded apps..."
find /Applications -maxdepth 1 -xattrname com.apple.quarantine -exec sudo xattr -dr com.apple.quarantine '{}' \;

