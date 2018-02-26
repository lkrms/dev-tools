#!/bin/bash

STAT_OPTIONS="-c %s"

if [ "$(uname)" == "Darwin" ]; then

    STAT_OPTIONS="-f %z"

fi

find . -type f -print0 | xargs -0 stat $STAT_OPTIONS | awk '{s+=$1} END {print s}'

