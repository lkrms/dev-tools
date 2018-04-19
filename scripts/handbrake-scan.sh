#!/bin/bash

HANDBRAKE_PATH="/usr/local/bin/HandBrakeCLI"

if [ ! -x "$HANDBRAKE_PATH" ]; then

    echo "Error: $HANDBRAKE_PATH does not exist or is not executable."
    exit 1

fi

while read -d $'\0' DVD_SOURCE; do

    echo "Scanning: $DVD_SOURCE"

    "$HANDBRAKE_PATH" --scan --title 0 --input "$DVD_SOURCE" >"$DVD_SOURCE.handbrake-scan" 2>&1 </dev/null

    HANDBRAKE_RESULT=$?

    echo "Exit code: $HANDBRAKE_RESULT"

done < <(find . -mindepth 1 -maxdepth 1 \( -type d -o -name '*.iso' \)  -print0 | sort -z)

