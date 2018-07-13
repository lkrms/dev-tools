#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

. "$SCRIPT_DIR/exif-settings" || . "$SCRIPT_DIR/exif-settings-default" || exit 2

if [ -n "$1" ]; then

    PHOTOS_ROOT="$1"

fi

if [ ! -d "$PHOTOS_ROOT" ]; then

    echo "Error: $PHOTOS_ROOT doesn't exist or isn't a directory"
    exit 2

fi

command -v exiftool >/dev/null 2>&1 || { echo "Error: exiftool not found"; exit 1; }

find "$PHOTOS_ROOT" -type f \( -iname '*.nef' \) -print0 | while read -d $'\0' PHOTO_FILE; do

    XMP_FILE="${PHOTO_FILE%.*}.xmp"

    if [ -e "$XMP_FILE" ]; then

        echo "Skipping (XMP file already exists): $PHOTO_FILE"

        continue

    fi

    exiftool -tagsFromFile "$PHOTO_FILE" \
        -d %Y \
        -Marked=true \
        '-Copyright<'"$EXIF_COPYRIGHT" \
        "-UsageTerms=$EXIF_USAGE_TERMS" \
        "-WebStatement=$EXIF_COPYRIGHT_INFO_URL" \
        "-Creator=$EXIF_CREATOR" \
        "-CreatorAddress=$EXIF_CREATOR_ADDRESS" \
        "-CreatorCity=$EXIF_CREATOR_CITY" \
        "-CreatorCountry=$EXIF_CREATOR_COUNTRY" \
        "-CreatorWorkEmail=$EXIF_CREATOR_EMAIL" \
        "-CreatorWorkTelephone=$EXIF_CREATOR_PHONE" \
        "-CreatorPostalCode=$EXIF_CREATOR_POSTAL_CODE" \
        "-CreatorRegion=$EXIF_CREATOR_REGION" \
        "-CreatorWorkURL=$EXIF_CREATOR_URL" \
        "$XMP_FILE"

done
