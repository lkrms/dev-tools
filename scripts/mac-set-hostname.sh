#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") <host-name>"
    exit 1

fi

sudo scutil --set ComputerName $1
sudo scutil --set LocalHostName $1
sudo scutil --set HostName $1

