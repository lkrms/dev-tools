#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"

SOURCE_PATH=
TARGET_EXTENSION=m4v
HANDBRAKE_PRESET="Fast 1080p30"

SOURCE_PATH2=
TARGET_EXTENSION2=m4v
HANDBRAKE_PRESET2="Fast 1080p30"

[ -e "$SCRIPT_DIR/handbrake-settings" ] && . "$SCRIPT_DIR/handbrake-settings"

[ -z "$SOURCE_PATH" ] && { echo "Error: SOURCE_PATH not provided."; exit 1; }
[ -z "$ARCHIVE_PATH" ] && ARCHIVE_PATH="$SOURCE_PATH/__converted"
[ -z "$TARGET_PATH" ] && TARGET_PATH="$SOURCE_PATH/__HandBrake"

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

if [ -n "$SOURCE_PATH2" ]; then

    [ -z "$ARCHIVE_PATH2" ] && ARCHIVE_PATH2="$SOURCE_PATH2/__converted"
    [ -z "$TARGET_PATH2" ] && TARGET_PATH2="$SOURCE_PATH2/__HandBrake"

    if [ ! -d "$SOURCE_PATH2" ]; then

        echo "Error: $SOURCE_PATH2 does not exist or is not a folder."
        exit 1

    fi

    if [ ! -d "$ARCHIVE_PATH2" ]; then

        echo "Error: $ARCHIVE_PATH2 does not exist or is not a folder."
        exit 1

    fi

    if [ ! -d "$TARGET_PATH2" ]; then

        echo "Error: $TARGET_PATH2 does not exist or is not a folder."
        exit 1

    fi

fi

command -v HandBrakeCLI >/dev/null 2>&1 || { echo "Error: HandBrakeCLI not found."; exit 1; }

function log_something {

    echo "$1"

    if [ "$DRY_RUN" -eq "0" ]; then

        echo "$(date '+%c') $1" >> "$LOG_FILE"

    fi

}

function sanitise_path {

    echo "$(dirname "$1")/$(basename "$1")"

}

function check_time {

    if [ "$FINISH_AFTER" -ne "0" -a "$FINISH_AFTER" -le "$(date +'%s')" ]; then

        log_something "Halting queue processing as requested."
        exit

    fi
}

function process_file {

    check_time

    SOURCE_FOLDER="$(dirname "$1")"
    SOURCE_FOLDER="${SOURCE_FOLDER/#$SOURCE_PATH/}"
    SOURCE_FOLDER="${SOURCE_FOLDER/#\//}"
    SOURCE_NAME="$(basename "$1")"
    SOURCE_NAME="${SOURCE_NAME/%.mkv/}"

    if [ -n "$2" ]; then

        SOURCE_NAME="$2"

    fi

    TARGET_FILE="$(sanitise_path "$TARGET_PATH/$SOURCE_FOLDER/$SOURCE_NAME.$TARGET_EXTENSION")"
    HANDBRAKE_LOG_FILE="$LOG_FILE_BASE.${1//\//-}.log"
    HANDBRAKE_LOG_FILE_STDOUT="$LOG_FILE_BASE.${1//\//-}.stdout.log"

    if [ -e "$TARGET_FILE" ]; then

        log_something "Target exists (skipping): $TARGET_FILE"
        return 0

    fi

    TEMP_TARGET_FILE="$(mktemp "/tmp/$SOURCE_NAME.$(date +'%s').XXX.$TARGET_EXTENSION")" || exit 2

    log_something "Encoding: $1 to $TEMP_TARGET_FILE with preset: $HANDBRAKE_PRESET"

    if [ "$DRY_RUN" -eq "0" ]; then

        mkdir -p "$(dirname "$TARGET_FILE")" || exit 2

        HandBrakeCLI --preset-import-gui --preset "$HANDBRAKE_PRESET" --input "$1" --output "$TEMP_TARGET_FILE" > >(tee "$HANDBRAKE_LOG_FILE_STDOUT") 2> >(tee "$HANDBRAKE_LOG_FILE" >&2) </dev/null

        HANDBRAKE_RESULT=$?

    else

        HANDBRAKE_RESULT=0

    fi

    log_something "Finished encoding (exit code $HANDBRAKE_RESULT): $1"

    if [ "$HANDBRAKE_RESULT" -eq "0" ]; then

        if [ "$DRY_RUN" -eq "0" ]; then

            mv -n "$TEMP_TARGET_FILE" "$TARGET_FILE"

            MOVE_RESULT=$?

            [ "$MOVE_RESULT" -eq "0" ] && rm "$HANDBRAKE_LOG_FILE_STDOUT"

        else

            rm "$TEMP_TARGET_FILE"

            MOVE_RESULT=0

        fi

        log_something "Moved $TEMP_TARGET_FILE to $TARGET_FILE (exit code $MOVE_RESULT)"

        # no archiving if the temp file didn't move successfully
        [ "$MOVE_RESULT" -eq "0" ] || return $MOVE_RESULT

        if [ -z "$2" ]; then

            ARCHIVE_FILE="$(sanitise_path "$ARCHIVE_PATH/$SOURCE_FOLDER/$(basename "$1")")"

            [ "$DRY_RUN" -eq "0" ] && { mkdir -p "$(dirname "$ARCHIVE_FILE")" || exit 2; }

            log_something "Moving: $1 to $ARCHIVE_FILE"

            if [ "$DRY_RUN" -eq "0" ]; then

                mv -n "$1" "$ARCHIVE_FILE"

                MOVE_RESULT=$?

            else

                MOVE_RESULT=0

            fi

            log_something "Move exit code: $MOVE_RESULT"

            return $MOVE_RESULT

        else

            return 0

        fi

    else

        [ "$DRY_RUN" -eq "0" -a -e "$TEMP_TARGET_FILE" ] && mv "$TEMP_TARGET_FILE" "$TEMP_TARGET_FILE.delete"

        return 2

    fi

}

function process_dvd {

    check_time

    SOURCE_FOLDER="$(dirname "$1")"
    SOURCE_FOLDER="${SOURCE_FOLDER/#$SOURCE_PATH/}"
    SOURCE_FOLDER="${SOURCE_FOLDER/#\//}"
    SOURCE_NAME="$(basename "$1")"
    SOURCE_NAME="${SOURCE_NAME/%.iso/}"

    if [ -n "$3" ]; then

        SOURCE_NAME="$3"

    fi

    TARGET_FILE="$(sanitise_path "$TARGET_PATH/$SOURCE_FOLDER/$SOURCE_NAME.$TARGET_EXTENSION")"
    HANDBRAKE_LOG_FILE="$LOG_FILE_BASE.${1//\//-}.$2.log"
    HANDBRAKE_LOG_FILE_STDOUT="$LOG_FILE_BASE.${1//\//-}.$2.stdout.log"

    if [ -e "$TARGET_FILE" ]; then

        log_something "Target exists (skipping): $TARGET_FILE"
        return 0

    fi

    log_something "Encoding: $1 (title $2) to $TARGET_FILE with preset: $HANDBRAKE_PRESET"

    if [ "$DRY_RUN" -eq "0" ]; then

        mkdir -p "$(dirname "$TARGET_FILE")" || exit 2

        HandBrakeCLI --preset-import-gui --preset "$HANDBRAKE_PRESET" --input "$1" --title "$2" --output "$TARGET_FILE" > >(tee "$HANDBRAKE_LOG_FILE_STDOUT") 2> >(tee "$HANDBRAKE_LOG_FILE" >&2) </dev/null

        HANDBRAKE_RESULT=$?

    else

        HANDBRAKE_RESULT=0

    fi

    log_something "Finished encoding (exit code $HANDBRAKE_RESULT): $1"

    if [ "$HANDBRAKE_RESULT" -eq "0" ]; then

        [ "$DRY_RUN" -eq "0" ] && rm "$HANDBRAKE_LOG_FILE_STDOUT"

        if [ -z "$3" ]; then

            ARCHIVE_FILE="$(sanitise_path "$ARCHIVE_PATH/$SOURCE_FOLDER/$(basename "$1")")"

            [ "$DRY_RUN" -eq "0" ] && { mkdir -p "$(dirname "$ARCHIVE_FILE")" || exit 2; }

            log_something "Moving: $1 to $ARCHIVE_FILE"

            if [ "$DRY_RUN" -eq "0" ]; then

                mv -n "$1" "$ARCHIVE_FILE"

                MOVE_RESULT=$?

            else

                MOVE_RESULT=0

            fi

            log_something "Move exit code: $MOVE_RESULT"

            return $MOVE_RESULT

        else

            return 0

        fi

    else

        [ "$DRY_RUN" -eq "0" -a -e "$TARGET_FILE" ] && mv "$TARGET_FILE" "$TARGET_FILE.delete"

        return 2

    fi

}

SOURCE_PATH="$(sanitise_path "$SOURCE_PATH")"
ARCHIVE_PATH="$(sanitise_path "$ARCHIVE_PATH")"
TARGET_PATH="$(sanitise_path "$TARGET_PATH")"

if [ -n "$SOURCE_PATH2" ]; then

    SOURCE_PATH2="$(sanitise_path "$SOURCE_PATH2")"
    ARCHIVE_PATH2="$(sanitise_path "$ARCHIVE_PATH2")"
    TARGET_PATH2="$(sanitise_path "$TARGET_PATH2")"

fi

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
LOG_DIR="$SCRIPT_DIR/log"
LOG_FILE_BASE="$LOG_DIR/$(basename "$0")"
LOG_FILE_BASE="${LOG_FILE_BASE/%.sh/}"
LOG_FILE="$LOG_FILE_BASE.log"

DRY_RUN=0
FINISH_AFTER=0

DATE_COMMAND=date

if [ "$(uname -s)" == "Darwin" ]; then

    DATE_COMMAND=gdate

fi

if [ "$1" == "dry" ]; then

    echo "DRY RUN: no files will be changed."

    DRY_RUN=1

elif [ -n "$1" ]; then

    FINISH_AFTER=$("$DATE_COMMAND" -d "$1" +'%s' 2>/dev/null) || { echo "Invalid time: $1"; exit 1; }

    mkdir -p "$LOG_DIR" || exit 2

    log_something "Queue processing will not continue after: $("$DATE_COMMAND" -d "@$FINISH_AFTER")"

else

    mkdir -p "$LOG_DIR" || exit 2

fi

while [ -n "$SOURCE_PATH" ]; do

    # movies first
    if [ -e "$SOURCE_PATH/titles.list" ]; then

        while IFS=',' read -r DVD_SOURCE DVD_TITLE; do

            if [ ! -z "$DVD_SOURCE" -a -e "$SOURCE_PATH/$DVD_SOURCE" -a ! -z "$DVD_TITLE" ]; then

                process_dvd "$SOURCE_PATH/$DVD_SOURCE" "$DVD_TITLE"

            fi

        done < "$SOURCE_PATH/titles.list"

    fi

    while read -d $'\0' SOURCE_FILE; do

        process_file "$SOURCE_FILE"

    done < <(find "$SOURCE_PATH" -maxdepth 1 -type f -name '*.mkv' ! -iname '* - Side *' ! -name '.*' -print0 | sort -z)

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
        ERRORS=0

        if [ -e "$FOLDER/titles.list" ]; then

            while IFS=',' read -r DVD_SOURCE DVD_TITLE; do

                let EPISODE=EPISODE+1

                if [ ! -z "$DVD_SOURCE" -a -e "$FOLDER/$DVD_SOURCE" -a ! -z "$DVD_TITLE" ]; then

                    process_dvd "$FOLDER/$DVD_SOURCE" "$DVD_TITLE" "${SERIES_NAME}${SEASON_NAME}_E$(printf "%02d" $EPISODE)" || let ERRORS=ERRORS+1

                fi

            done < "$FOLDER/titles.list"

        fi

        while read -d $'\0' SOURCE_FILE; do

            let EPISODE=EPISODE+1

            process_file "$SOURCE_FILE" "${SERIES_NAME}${SEASON_NAME}_E$(printf "%02d" $EPISODE)" || let ERRORS=ERRORS+1

        done < <(find "$FOLDER" -maxdepth 1 -type f -name '*.mkv' ! -iname '* - Side *' ! -name '.*' -print0 | sort -z)

        if [ "$EPISODE" -gt "0" -a "$ERRORS" -eq "0" ]; then

            ARCHIVE_FOLDER="$(sanitise_path "$ARCHIVE_PATH/$RELATIVE_FOLDER")"

            [ "$DRY_RUN" -eq "0" ] && { mkdir -p "$(dirname "$ARCHIVE_FOLDER")" || exit 2; }

            log_something "Moving folder: $FOLDER to $ARCHIVE_FOLDER"

            if [ "$DRY_RUN" -eq "0" ]; then

                mv -n "$FOLDER" "$ARCHIVE_FOLDER"

                MOVE_RESULT=$?

            else

                MOVE_RESULT=0

            fi

            log_something "Move exit code: $MOVE_RESULT"

        fi

    done < <(find "$SOURCE_PATH" -mindepth 1 -maxdepth 2 -type d ! -path '*/__*' ! -name '.*' -print0 | sort -z)

    SOURCE_PATH="$SOURCE_PATH2"
    ARCHIVE_PATH="$ARCHIVE_PATH2"
    TARGET_PATH="$TARGET_PATH2"
    TARGET_EXTENSION="$TARGET_EXTENSION2"
    HANDBRAKE_PRESET="$HANDBRAKE_PRESET2"
    SOURCE_PATH2=

done
