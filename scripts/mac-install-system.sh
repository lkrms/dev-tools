#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") </path/to/downloads/folder>"
    exit 1

fi

if [ ! -d "$1" ]; then

    echo "Error: $1 doesn't exist or isn't a folder."
    exit 2

fi

LOCAL_PATH="$HOME/Downloads/_install"
DOWNLOADS_PATH="$1"

mkdir -p "$LOCAL_PATH" || exit 3

echo -e "Copying everything you might need...\n"

function package_get {

    # don't do anything if the application is already installed
    if [ ! -e "$2" ]; then

        # identify the most recent file matching the provided spec
        PACKAGE_PATH="$(find "$DOWNLOADS_PATH" -type f -name "$1" -print0 | xargs -0 stat -f '%m :%N' | sort -nr | cut -d: -f2- | head -n1)"

        if [ -z "$PACKAGE_PATH" ]; then

            echo "Unable to find a package file matching: $1"

        else

            cp -pv "$PACKAGE_PATH" "$LOCAL_PATH"

        fi

    fi

}

package_get "iTerm2*" "/Applications/iTerm.app"

echo -e "\n\nDone."

