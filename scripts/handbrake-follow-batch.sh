#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
LOG_DIR="$SCRIPT_DIR/log"
LOG_FILE="$LOG_DIR/handbrake-batch.log"

if [ -e "$LOG_FILE" ]; then

    tail -n 100 -f "$LOG_FILE"

else

    echo "Log file not found."

fi

