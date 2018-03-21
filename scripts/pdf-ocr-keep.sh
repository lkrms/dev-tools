#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

find . -type f -name '*_OCR.*' -print0 | while read -d $'\0' file; do

    mv -fv "$file" "${file%_OCR.*}.${file##*.}"

done

