#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

if [ -e "$SCRIPT_DIR/exif-settings" ]; then

    . "$SCRIPT_DIR/exif-settings"

else

    . "$SCRIPT_DIR/exif-settings-default" || exit 2

fi

if [ -n "$1" ]; then

    PHOTOS_ROOT="$1"

fi

if [ ! -d "$PHOTOS_ROOT" ]; then

    echo "Error: $PHOTOS_ROOT doesn't exist or isn't a directory"
    exit 2

fi

command -v exiftool &>/dev/null || { echo "Error: exiftool not found"; exit 1; }
command -v exiftran &>/dev/null || { echo "Error: exiftran not found"; exit 1; }

function extractPreview {

    THIS_TARGET="$TARGET_FOLDER"
    [ -z "$THIS_TARGET" ] && THIS_TARGET="$(basename "$(dirname "$(realpath "$1")")")"
    THIS_TARGET="$EXPORTS_ROOT/$THIS_TARGET"

    mkdir -p "$THIS_TARGET" || exit 2

    XMP_FILE="${1%.*}.xmp"
    TARGET_FILE="$THIS_TARGET/$(basename "${1%.*}.jpg")"

    # extract the JPEG
    exiftool -b $2 "$1" > "$TARGET_FILE"

    # copy [necessary] metadata
    exiftool -overwrite_original -tagsFromFile "$1" -Orientation "$TARGET_FILE"
    [ -e "$XMP_FILE" ] && exiftool -overwrite_original -tagsFromFile "$XMP_FILE" "$TARGET_FILE"

    # rotate the JPEG if needed
    exiftran -ai "$TARGET_FILE"

    # downsample for online proofing etc.
    convert "$TARGET_FILE" -scale "$EXPORT_GEOMETRY" -interpolate bicubic -quality $EXPORT_QUALITY "$TARGET_FILE"

}

TARGET_FOLDER=

[ -n "$2" ] && TARGET_FOLDER="$2"

TEMP_FILE="$(mktemp "/tmp/$(basename "$0").XXXXXXX")"

# identify photos based on the preview tags they contain
exiftool --ext xmp -if '$JpgFromRaw' -p '-JpgFromRaw $Directory/$Filename' -r "$PHOTOS_ROOT" > "$TEMP_FILE"
exiftool --ext xmp -if 'not $JpgFromRaw' -if '$PreviewImage' -p '-PreviewImage $Directory/$Filename' -r "$PHOTOS_ROOT" >> "$TEMP_FILE"

while read META_TAG PHOTO_FILE; do

    # keep our subprocesses in check
    while [ "$(jobs -p | wc -l)" -gt "$MAX_PROCESSES" ]; do

        sleep 1;

    done

    (
        extractPreview "$PHOTO_FILE" $META_TAG
    ) &>/dev/null &

    echo "Processing ${PHOTO_FILE}..."

done < "$TEMP_FILE"

wait

