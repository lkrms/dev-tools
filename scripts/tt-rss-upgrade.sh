#!/bin/bash

# POC: could be adapted to work with any repo, not just tt-rss

if [ "$#" -lt "1" -o "$#" -gt 2 ]; then

    >&2 echo "Usage: $(basename "$0") /path/to/my/tt-rss [repo_username]"
    exit

fi

GIT_SUDO=

if [ -n "$2" ]; then

    if [ "$EUID" -ne "0" ]; then

        >&2 echo "Error: this script must be run as root when specifying a repo username."
        exit 1

    fi

    GIT_SUDO="sudo -u $2"

fi

pushd "$1" >/dev/null || exit

# grab the latest code
$GIT_SUDO git fetch --quiet origin master || exit

# are we current?
LOCAL=$($GIT_SUDO git rev-parse @{0}) || exit
REMOTE=$($GIT_SUDO git rev-parse @{u}) || exit
BASE=$($GIT_SUDO git merge-base @ @{u}) || exit

if [ $LOCAL != $REMOTE ]; then

    if [ $LOCAL = $BASE ]; then

        >&2 echo "Tiny Tiny RSS at $1 is out of date. Updating:"
        >&2 $GIT_SUDO git merge FETCH_HEAD || exit

    else

        >&2 echo "Tiny Tiny RSS at $1 is out of date. Automatic update not possible. Please fix."

    fi

fi

popd  >/dev/null

