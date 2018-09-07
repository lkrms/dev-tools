#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

if [ -e "$SCRIPT_DIR/exif-settings" ]; then

    . "$SCRIPT_DIR/exif-settings"

else

    . "$SCRIPT_DIR/exif-settings-default" || exit 2

fi

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") DIR"
    exit 1

fi

PHOTOS_DIR="$1"

if [ ! -d "$PHOTOS_DIR" ]; then

    echo "Error: $PHOTOS_DIR doesn't exist or isn't a directory"
    exit 2

fi

command -v exiftool >/dev/null 2>&1 || { echo "Error: exiftool not found"; exit 1; }

TEMP_FILE="$(mktemp "/tmp/$(basename "$0").XXXXXXX")"

function doRename () {

    local SEQ=0 TIMESTAMP XMP_PATH RENAME_PATH RENAME_TO RENAME RENAME_EXT RENAME_PATH

    # gather CreateDates into a sortable list
    exiftool --ext xmp -srcfile '%d%f.xmp' -d %s -p '$CreateDate $Directory/$FileName' "$PHOTOS_DIR" | sort -n > "$TEMP_FILE" || exit 2

    while read TIMESTAMP XMP_PATH; do

        let SEQ+=1

        RENAME_PATH="${XMP_PATH%.*}"
        RENAME_TO="$(date -d "@$TIMESTAMP" +'%y%m%d')_$(printf "%04d" $SEQ)"

        # don't do any unnecessary renaming
        if [ "$(basename "$RENAME_PATH")" == "$RENAME_TO" ]; then

            continue

        fi

        RENAME_TO="${RENAME_TO}${1}"

        for RENAME in "$RENAME_PATH".*; do

            # the glob above ensures there will always be an extension
            RENAME_EXT=".${RENAME##*.}"
            RENAME_PATH="$(dirname "$RENAME")"

            echo "$(basename "$RENAME") -> ${RENAME_TO}${RENAME_EXT}"
            mv -n "$RENAME" "${RENAME_PATH}/${RENAME_TO}${RENAME_EXT}" || exit 2

        done

    done < "$TEMP_FILE"

}

RENAME_COUNT=0

# pass 1: rename with a unique suffix (so we don't overwrite anything)
doRename "_$(date +'%s')"

RENAME_COUNT=0

# pass 2: rename without a suffix
doRename ''

echo -e "\nAll done!\n"
