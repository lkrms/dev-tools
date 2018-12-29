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
[ -e "/Applications/Adobe DNG Converter.app/Contents/MacOS/Adobe DNG Converter" ] || { echo "Error: Adobe DNG Converter not found"; exit 1; }

CAMERA_MAKE="FUJIFILM"
CAMERA_MODEL="XF10"

[ -n "$2" ] && CAMERA_MAKE="$2"
[ -n "$3" ] && CAMERA_MODEL="$3"

TEMP_FILE="$(mktemp "/tmp/$(basename "$0").XXXXXXX")"

# identify photos based on the camera used
exiftool --ext xmp --ext dng -if '$Make eq "'"$CAMERA_MAKE"'"' -if '$Model eq "'"$CAMERA_MODEL"'"' -p '$Directory/$Filename' -r "$PHOTOS_ROOT" > "$TEMP_FILE"

while read PHOTO_FILE; do

    echo -n "Processing ${PHOTO_FILE}..."

    PHOTO_NAME="${PHOTO_FILE%.*}"

    if [ -e "${PHOTO_NAME}.dng" -o -e "${PHOTO_NAME}.DNG" ]; then

        echo " DNG already exists, skipping."
        continue

    fi

    echo " DNG not found, converting now..."
    open -Wa "/Applications/Adobe DNG Converter.app/Contents/MacOS/Adobe DNG Converter" --args -c -p2 "$PHOTO_FILE"

done < "$TEMP_FILE"

