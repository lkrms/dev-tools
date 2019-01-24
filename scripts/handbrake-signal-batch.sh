#!/bin/bash

trap "exit" INT TERM
trap "kill 0" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd -P)"

RUN_DIR="$SCRIPT_DIR/run"
FIFO_FILE="$RUN_DIR/handbrake-batch.fifo"

[ -n "$1" ] || exit
[ -p "$FIFO_FILE" ] || exit

(
    echo "$1" > $FIFO_FILE
) &

sleep 1

