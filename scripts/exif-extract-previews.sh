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

command -v exiftool >/dev/null 2>&1 || { echo "Error: exiftool not found"; exit 1; }
command -v exiftran >/dev/null 2>&1 || { echo "Error: exiftran not found"; exit 1; }

find "$PHOTOS_ROOT" -type f \( -iname '*.nef' \) -print0 | sort -z | while read -d $'\0' PHOTO_FILE; do

    if [ -n "$2" ]; then

        TARGET_FOLDER="$2"

    else

        TARGET_FOLDER="$(basename "$(dirname "$(realpath "$PHOTO_FILE")")")"

    fi

    mkdir -p "$EXPORTS_ROOT/$TARGET_FOLDER" || exit 2

    XMP_FILE="${PHOTO_FILE%.*}.xmp"
    TARGET_FILE="$EXPORTS_ROOT/$TARGET_FOLDER/$(basename "${PHOTO_FILE%.*}.jpg")"

    # extract the JPEG
    exiftool -b -JpgFromRaw "$PHOTO_FILE" > "$TARGET_FILE"

    # copy [necessary] metadata
    exiftool -overwrite_original -tagsFromFile "$PHOTO_FILE" -Orientation "$TARGET_FILE"
    [ -e "$XMP_FILE" ] && exiftool -overwrite_original -tagsFromFile "$XMP_FILE" "$TARGET_FILE"

    # rotate the JPEG if needed
    exiftran -ai "$TARGET_FILE"

    # downsample for online proofing etc.
    convert "$TARGET_FILE" -scale "$EXPORT_GEOMETRY" -interpolate bicubic -quality $EXPORT_QUALITY "$TARGET_FILE"

done

