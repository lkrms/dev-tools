#!/bin/bash

if [ "$(uname -s)" == "Linux" ]; then

    pkill -fU "$USER" '^ssh.*\[mux\]'

elif [ "$(uname -s)" == "Darwin" ]; then

    pkill -lU "$USER" '^ssh.*\[mux\]'

else

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

