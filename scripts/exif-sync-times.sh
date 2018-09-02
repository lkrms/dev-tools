#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# set to 1 if ALL metadata should be copied to the XMP sidecar
COPY_EXIF_FROM_SOURCE=0

# if your camera uses a different tag for its unique identifier, add it here (order reflects priority)
SERIAL_NUMBER_TAGS="-SerialNumber -InternalSerialNumber"

GET_CREATE_TIME_TAGS="-DateTimeOriginal -CreateDate"

if [ -e "$SCRIPT_DIR/exif-settings" ]; then

    . "$SCRIPT_DIR/exif-settings"

else

    . "$SCRIPT_DIR/exif-settings-default" || exit 2

fi

if [ "$#" -lt "2" ]; then

    echo "Usage: $(basename "$0") </path/to/sync_photo_1.ext> </path/to/sync_photo_2.ext> [...]"
    exit 1

fi

command -v exiftool >/dev/null 2>&1 || { echo "Error: exiftool not found"; exit 1; }

function inArray () {

    local ELEMENT MATCH="$1"

    shift

    for ELEMENT in "$@"; do

        [[ "$ELEMENT" == "$MATCH" ]] && return 0

    done

    return 1

}

SYNC_DIR=
CAMERA_SERIALS=()
CAMERA_TIMES=()
TIME_SHIFTS=()

for SYNC_PHOTO in "$@"; do

    if [ ! -f "$SYNC_PHOTO" ]; then

        echo "Error: $SYNC_PHOTO doesn't exist or isn't a file."
        exit 2

    fi

    if [ -z "$SYNC_DIR" ]; then

        SYNC_DIR="$(dirname "$(realpath "$SYNC_PHOTO")")"

    elif [ "$(dirname "$(realpath "$SYNC_PHOTO")")" != "$SYNC_DIR" ]; then

        echo "Error: all photos must be in the same directory."
        exit 2

    fi

    SERIAL_NUMBER="$(exiftool -s3 $SERIAL_NUMBER_TAGS "$SYNC_PHOTO" | head -n1)"
    CREATE_TIME="$(exiftool -s3 -d '%Y-%m-%d %H:%M:%S' $GET_CREATE_TIME_TAGS "$SYNC_PHOTO" | head -n1)"

    if [ -z "$SERIAL_NUMBER" -o -z "$CREATE_TIME" ]; then

        echo "Error: unable to retrieve metadata from: $SYNC_PHOTO"
        exit 2

    fi

    if inArray "$SERIAL_NUMBER" "${CAMERA_SERIALS[@]}"; then

        echo "Error: multiple photos from the same camera were provided."
        exit 2

    fi

    # convert Y-m-d H:M:S to timestamp
    CREATE_TIME=$(date -d "$CREATE_TIME" +'%s')

    CAMERA_SERIALS=("${CAMERA_SERIALS[@]}" "$SERIAL_NUMBER")
    CAMERA_TIMES=("${CAMERA_TIMES[@]}" "$CREATE_TIME")

    echo -e "\nCamera with identifier '$SERIAL_NUMBER' has timestamp: $(date -d "@$CREATE_TIME")"

    if [ "${#CAMERA_TIMES[@]}" -gt "1" ]; then

        # if this the second or a subsequent camera, calculate the timeshift
        BASE_TIME=${CAMERA_TIMES[0]}

        let TIME_SHIFT=BASE_TIME-CREATE_TIME
        TIME_SHIFTS=("${TIME_SHIFTS[@]}" $TIME_SHIFT)

        echo "Photos taken with this camera will be time shifted by $TIME_SHIFT seconds."

    fi

done

echo -e "\nAll photos in $SYNC_DIR will be synchronised.\n"

