#!/bin/bash

command -v HandBrakeCLI >/dev/null 2>&1 || { echo "Error: HandBrakeCLI not found."; exit 1; }

function log_something {

    echo "$1"

    echo "$(date '+%c') $1" >> "$LOG_FILE"

}

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
LOG_DIR="$SCRIPT_DIR/log"
LOG_FILE_BASE="$LOG_DIR/$(basename "$0")"
LOG_FILE_BASE="${LOG_FILE_BASE/%.sh/}"
LOG_FILE="$LOG_FILE_BASE.log"

while read -d $'\0' DVD_SOURCE; do

    log_something "Scanning: $DVD_SOURCE"

    HandBrakeCLI --scan --title 0 --input "$DVD_SOURCE" </dev/null 2>&1 | grep '^[[:space:]]*+' >"$DVD_SOURCE.handbrake-scan"

    HANDBRAKE_RESULT=$?

    log_something "Finished scanning (exit code $HANDBRAKE_RESULT): $DVD_SOURCE"

done < <(find . -mindepth 1 -maxdepth 1 \( -type d -o -name '*.iso' \)  -print0 | sort -z)

