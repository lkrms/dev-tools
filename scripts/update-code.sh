#!/bin/bash

SOURCE_PATH="$HOME/Code"

if [ ! -e "$SOURCE_PATH" ]; then

    echo "Error: $SOURCE_PATH does not exist."
    exit 1

fi

command -v git >/dev/null 2>&1 || { echo "Error: Git not found."; exit 1; }

CHANGED_REPOS=""
STALE_REPOS=""

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

while read -d $'\0' FOLDER; do

    cd "$FOLDER/.."

    REPO_PATH="${FOLDER/#$SOURCE_PATH\//}"
    REPO_PATH="${REPO_PATH/%\/.git/}"

    echo -e "Updating ${BOLD}${REPO_PATH}${NC} using Git..."

    if [ "$(git remote)" != "" ]; then

        git pull

    else

        echo -e "${RED}Warning: no remotes configured.${NC}"

    fi

    if [ "$(git status -s)" != "" ]; then

        CHANGED_REPOS+=" ${RED}${REPO_PATH}${NC}"

    fi

    STALE_REMOTES=""

    while read REMOTE; do

        if ! git diff --quiet "$REMOTE..HEAD" --; then

            STALE_REMOTES+="${BLUE}$REMOTE${NC},"

        fi

    done < <(git remote)

    if [ "$STALE_REMOTES" != "" ]; then

        STALE_REMOTES="${STALE_REMOTES/%,/}"
        STALE_REPOS+=" ${RED}${REPO_PATH}${NC}(${STALE_REMOTES})"

    fi

    echo -e "Done updating ${BOLD}${REPO_PATH}${NC}.\n\n"

done < <(find "$SOURCE_PATH" -maxdepth 3 -type d -name .git -print0 | sort -z)

if [ "$CHANGED_REPOS" == "" ]; then

    CHANGED_REPOS=" ${GREEN}NONE${NC}"

fi

if [ "$STALE_REPOS" == "" ]; then

    STALE_REPOS=" ${GREEN}NONE${NC}"

fi

echo -e "Repositories with uncommitted changes:$CHANGED_REPOS\n\n"

echo -e "Repositories with unpushed changes:$STALE_REPOS\n\n"

