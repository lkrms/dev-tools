#!/bin/bash

SOURCE_PATH="/Volumes/shared/rips"
ARCHIVE_PATH="/Volumes/shared/rips/__converted"
TARGET_PATH="/Volumes/Data/HandBrake"
HANDBRAKE_PATH="/usr/local/bin/HandBrakeCLI"
HANDBRAKE_PRESET="DVD (fast) + Subtitles"

if [ ! -d "$SOURCE_PATH" ]; then

    echo "Error: $SOURCE_PATH does not exist or is not a folder."
    exit 1

fi

if [ ! -d "$ARCHIVE_PATH" ]; then

    echo "Error: $ARCHIVE_PATH does not exist or is not a folder."
    exit 1

fi

if [ ! -d "$TARGET_PATH" ]; then

    echo "Error: $TARGET_PATH does not exist or is not a folder."
    exit 1

fi

if [ ! -x "$HANDBRAKE_PATH" ]; then

    echo "Error: $HANDBRAKE_PATH does not exist or is not executable."
    exit 1

fi

function log_something {

    echo "$1"
    echo "$(date '+%c') $1" >> "$LOG_FILE"

}

function sanitise_path {

    echo "$(dirname "$1")/$(basename "$1")"

}

function process_file {

    SOURCE_FOLDER="$(dirname "$1")"
    SOURCE_FOLDER="${SOURCE_FOLDER/#$SOURCE_PATH/}"
    SOURCE_FOLDER="${SOURCE_FOLDER/#\//}"
    SOURCE_NAME="$(basename "$1")"
    SOURCE_NAME="${SOURCE_NAME/%.mkv/}"

    if [ -n "$2" ]; then

        SOURCE_NAME="$2"

    fi

    TARGET_FILE="$(sanitise_path "$TARGET_PATH/$SOURCE_FOLDER/$SOURCE_NAME.m4v")"
    HANDBRAKE_LOG_FILE="$LOG_FILE_BASE.${1//\//-}.log"
    HANDBRAKE_LOG_FILE_STDOUT="$LOG_FILE_BASE.${1//\//-}.stdout.log"

    if [ -e "$TARGET_FILE" ]; then

        log_something "Target exists (skipping): $TARGET_FILE"
        return 1

    fi

    mkdir -p "$(dirname "$TARGET_FILE")" || exit 2

    log_something "Encoding: $1 to $TARGET_FILE"

    "$HANDBRAKE_PATH" --preset-import-gui --preset "$HANDBRAKE_PRESET" --input "$1" --output "$TARGET_FILE" > >(tee "$HANDBRAKE_LOG_FILE_STDOUT") 2> >(tee "$HANDBRAKE_LOG_FILE" >&2) </dev/null

    HANDBRAKE_RESULT=$?

    log_something "Finished encoding (exit code $HANDBRAKE_RESULT): $1"

    if [ "$HANDBRAKE_RESULT" -eq "0" -a -z "$2" ]; then

        ARCHIVE_FILE="$(sanitise_path "$ARCHIVE_PATH/$SOURCE_FOLDER/$(basename "$1")")"

        mkdir -p "$(dirname "$ARCHIVE_FILE")" || exit 2

        log_something "Moving: $1 to $ARCHIVE_FILE"

        mv -n "$1" "$ARCHIVE_FILE"

        MOVE_RESULT=$?

        log_something "Move exit code: $MOVE_RESULT"

    fi

}

SOURCE_PATH="$(sanitise_path "$SOURCE_PATH")"
ARCHIVE_PATH="$(sanitise_path "$ARCHIVE_PATH")"
TARGET_PATH="$(sanitise_path "$TARGET_PATH")"

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
LOG_DIR="$SCRIPT_DIR/log"
LOG_FILE_BASE="$LOG_DIR/$(basename "$0")"
LOG_FILE_BASE="${LOG_FILE_BASE/%.sh/}"
LOG_FILE="$LOG_FILE_BASE.log"

mkdir -p "$LOG_DIR" || exit 2

# movies first
while read -d $'\0' SOURCE_FILE; do

    process_file "$SOURCE_FILE"

done < <(find "$SOURCE_PATH" -maxdepth 1 -type f -name '*.mkv' ! -iname '* - Side *' -print0 | sort -z)

# TV shows second
while read -d $'\0' FOLDER; do

    RELATIVE_FOLDER="${FOLDER/#$SOURCE_PATH/}"
    RELATIVE_FOLDER="${RELATIVE_FOLDER/#\//}"

    SERIES_NAME="${RELATIVE_FOLDER/%\/*/}"
    SEASON_NAME="${RELATIVE_FOLDER/#*\//}"

    if [ "$SERIES_NAME" == "$SEASON_NAME" ]; then

        SEASON_NAME=

    else

        SEASON_NAME="_S${SEASON_NAME//[^0-9]/}"

    fi

    EPISODE=0

    while read -d $'\0' SOURCE_FILE; do

        let EPISODE=EPISODE+1

        process_file "$SOURCE_FILE" "${SERIES_NAME}${SEASON_NAME}_E$(printf "%02d" $EPISODE)"

    done < <(find "$FOLDER" -maxdepth 1 -type f -name '*.mkv' ! -iname '* - Side *' -print0 | sort -z)

done < <(find "$SOURCE_PATH" -mindepth 1 -maxdepth 2 -type d ! -path '*/__*' -print0 | sort -z)

