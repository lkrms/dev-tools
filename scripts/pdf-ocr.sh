#!/bin/bash

# Dependency: ABBYY FineReader for ScanSnap, pre-configured to automatically process PDFs on opening.

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

SCRIPTDIR="$(dirname "$0")"
SET_CREATOR_SCRIPT="$SCRIPTDIR/pdf-set-creator.py"

find . -type f -iname '*.pdf' -print0 | while read -d $'\0' file; do

    if ! grep -q Font "$file"; then

        ORIGINAL_FILE="$file"

        if ! grep -q '(ScanSnap Manager' "$file"; then

            ORIGINAL_FILE="$(mktemp "/tmp/$(basename "$file").XXXXXXX")" || exit 2
            mv -v "$file" "$ORIGINAL_FILE" || exit 2

            if ! "$SET_CREATOR_SCRIPT" "$ORIGINAL_FILE" "$file" "ScanSnap Manager #S1300i"; then

                echo "Error setting creator on: $file"
                mv -vf "$ORIGINAL_FILE" "$file"

                continue

            fi

        fi

        echo "Converting: $file"

        open -W -a "ABBYY FineReader for ScanSnap.app" "$file"

    fi

done

echo "Finished. You probably also want to run: pdf-ocr-keep.sh"

