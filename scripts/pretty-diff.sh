#!/bin/bash

if [ "$#" -ne "2" ]; then

    echo "Usage: $(basename "$0") <file1> <file2>"
    exit 1

fi

if [ ! -f "$1" ]; then

    echo "Error: $1 is not a file"
    exit 1

fi

if [ ! -f "$2" ]; then

    echo "Error: $2 is not a file"
    exit 1

fi

FILEMERGE_PATH="/Applications/Xcode.app/Contents/Applications/FileMerge.app/Contents/MacOS/FileMerge"

if [ -x "$FILEMERGE_PATH" ]; then

    "$FILEMERGE_PATH" -left "$1" -right "$2"

else

    echo "Error: no pretty diff tool found"
    exit 1

fi

