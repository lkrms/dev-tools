#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") <path/to/file.ext>"
    exit 1

fi

if [ ! -f "$1" ]; then

    echo "Not a file: $1"
    exit 1

fi

command -v GetFileInfo >/dev/null 2>&1 || { echo "GetFileInfo not found."; exit 2; }
command -v SetFile >/dev/null 2>&1 || { echo "SetFile not found."; exit 2; }

if [ "$(GetFileInfo -ae "$1")" -eq "1" ]; then

    echo "Unhiding extension for $1..."
    SetFile -a e "$1"

fi

