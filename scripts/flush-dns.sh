#!/bin/bash

if [ "$(uname -s)" == "Linux" ]; then

    # TODO: make this work with other Linux variants
    sudo systemd-resolve --flush-caches

elif [ "$(uname -s)" == "Darwin" ]; then

    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    sudo killall mDNSResponderHelper

else

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

