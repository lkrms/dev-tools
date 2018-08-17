#!/bin/bash

SCRIPTDIR="$(dirname "$0")"

find . -type f -iname '*.pdf' -print0 | while read -d $'\0' file; do

    if ! grep -q Font "$file"; then

        if ! grep -q '(ScanSnap Manager' "$file"; then

            echo "Not ScanSnap: $file"

        else

            echo "ScanSnap: $file"

        fi

    else

        echo "OK: $file"

    fi

done

