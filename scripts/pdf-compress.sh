#!/bin/bash

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") </path/to/my.pdf>"
    exit 1

fi

if [ ! -f "$1" ]; then

    echo "Error: $1 is not a file"
    exit 1

fi

command -v gs &>/dev/null || { echo "Error: Ghostscript not found"; exit 1; }

STAT_OPTIONS="-Lc %s"

if [ "$(uname -s)" == "Darwin" ]; then

    STAT_OPTIONS="-Lf %z"

fi

TEMP_FILE="$(dirname "$1")/notcompressed.$(basename "$1")"

mv -f "$1" "$TEMP_FILE" || exit 2

# minimum = minimum file size (maximum compression)
MINIMUM_DICT="<< /HSamples [2 1 1 2] /VSamples [2 1 1 2] /QFactor 2.40 /Blend 1 >>"
LOW_DICT="<< /HSamples [2 1 1 2] /VSamples [2 1 1 2] /QFactor 1.30 /Blend 1 >>"
MEDIUM_DICT="<< /HSamples [2 1 1 2] /VSamples [2 1 1 2] /QFactor 0.76 /Blend 1 >>"
HIGH_DICT="<< /HSamples [1 1 1 1] /VSamples [1 1 1 1] /QFactor 0.40 /Blend 1 >>"
MAXIMUM_DICT="<< /HSamples [1 1 1 1] /VSamples [1 1 1 1] /QFactor 0.15 /Blend 1 >>"

CUSTOM_DICT="<< /HSamples [2 1 1 2] /VSamples [2 1 1 2] /QFactor 1.04 /Blend 1 >>"

SELECTED_DICT=$CUSTOM_DICT

GRAY_RES=144
COLOR_RES=144
#GRAY_RES=200
#COLOR_RES=200

PS_COMMAND=".setpdfwrite << /ColorImageDict $SELECTED_DICT /GrayImageDict $SELECTED_DICT /GrayACSImageDict $SELECTED_DICT /ColorACSImageDict $SELECTED_DICT /GrayImageResolution $GRAY_RES /ColorImageResolution $COLOR_RES /ColorImageDownsampleType /Average /GrayImageDownsampleType /Average /MonoImageDownsampleType /Subsample /CompatibilityLevel 1.5 >> setdistillerparams"

gs -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -o "$1" -c "$PS_COMMAND" -f "$TEMP_FILE" || exit 2

OLD_SIZE=$(stat $STAT_OPTIONS "$TEMP_FILE")
NEW_SIZE=$(stat $STAT_OPTIONS "$1")
PERCENT_SAVED=$(bc <<< "($OLD_SIZE - $NEW_SIZE) * 100 / $OLD_SIZE")

echo -e "Compression complete. Was: $OLD_SIZE bytes. Now: $NEW_SIZE bytes. Saving: $PERCENT_SAVED%\n"

echo "Original PDF moved to: $TEMP_FILE"
