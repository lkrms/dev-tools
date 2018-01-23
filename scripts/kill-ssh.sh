#!/bin/bash

if [ "$(uname -s)" == "Linux" ]; then

    pkill -fU "$USER" '^ssh.*\[mux\]'

elif [ "$(uname -s)" == "Darwin" ]; then

    pkill -lU "$USER" '^ssh.*\[mux\]'

fi

