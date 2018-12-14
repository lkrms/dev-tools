#!/bin/bash

if [ "$#" -lt "1" -o "$#" -gt "2" ]; then

    echo "Usage: $(basename "$0") /path/to/my.md [/path/to/my.pdf]"
    exit 1

fi

if [ ! -f "$1" ]; then

    echo "Error: $1 is not a file"
    exit 1

fi

command -v pandoc >/dev/null 2>&1 || { echo "Error: pandoc not found"; exit 1; }

OUTPUT_FILE="$2"

if [ -z "$OUTPUT_FILE" ]; then

    OUTPUT_FILE="$(dirname "$1")/$(basename "${1%.*}.pdf")"

elif [ -d "$OUTPUT_FILE" ]; then

    OUTPUT_FILE="${2%/}/$(basename "${1%.*}.pdf")"

fi

function add_option {

    PANDOC_OPTIONS[${#PANDOC_OPTIONS[@]}]="$1"

}

PANDOC_OPTIONS=(--number-sections -V geometry:margin=2cm -V papersize=a4)

if pandoc -h | grep -q pdf-engine; then

    add_option --pdf-engine=lualatex

else

    add_option --latex-engine=lualatex

fi

TEMPLATE_PATH="$(dirname "$0")/$(basename "${0%.*}.latex")"

if [ -e "$TEMPLATE_PATH" ]; then

    add_option "--template=$TEMPLATE_PATH"

fi

pandoc "${PANDOC_OPTIONS[@]}" -o "$OUTPUT_FILE" "$1" || exit 2

echo "Converted $1 to: $OUTPUT_FILE"

command -v xdg-open >/dev/null 2>&1 && { nohup xdg-open "$OUTPUT_FILE" >/dev/null 2>&1 & exit; }
command -v open >/dev/null 2>&1 && { open "$OUTPUT_FILE"; exit; }

