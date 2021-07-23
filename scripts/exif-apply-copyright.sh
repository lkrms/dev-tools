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

TEMP_FILE="$(mktemp "/tmp/$(basename "$0").XXXXXXX")"

# first, make sure we have a full set of XMP sidecars (FileName is quick to copy and handy in the next step, and Creator will be overwritten shortly)
exiftool -overwrite_original --ext xmp -tagsFromFile @ -srcfile '%d%f.xmp' '-Creator<FileName' -r "$PHOTOS_ROOT" || exit 2

# next, identify XMP sidecars with no CreateDate
exiftool --ext xmp -srcfile '%d%f.xmp' -if 'not $CreateDate' -p '$Directory/$Creator' -r "$PHOTOS_ROOT" > "$TEMP_FILE"

# (exit code is 2 if no files match, so we have to be more specific with our error checking)
if [ "$?" -eq "1" ]; then

    exit 2

fi

# populate them with CreateDate
if [ "$(cat "$TEMP_FILE" | wc -l)" -gt "0" ]; then

    exiftool -@ "$TEMP_FILE" -overwrite_original -tagsFromFile @ -srcfile "%d%f.xmp" -CreateDate || exit 2

fi

# finally, apply copyright metadata to all sidecars
exiftool -overwrite_original --ext xmp -srcfile "%d%f.xmp" -d %Y \
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
    -r "$PHOTOS_ROOT" || exit 2

echo -e "\nAll done!\n"
