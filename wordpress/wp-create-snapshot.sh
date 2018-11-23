#!/bin/bash

SCRIPT_PATH="${BASH_SOURCE[0]}"
[ -h "$SCRIPT_PATH" ] && SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)" || exit 2

. "$SCRIPT_DIR/common"

check_not_root
check_wp_cli

SITE_URL="$(wp option get siteurl)" || exit 2
SITE_DOMAIN="$(echo "$SITE_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||')"

DB_NAME="$(wp config get DB_NAME)" || exit 2

SNAPSHOT_TIMESTAMP="$(date +'%Y%m%d-%H%M%S')"
FILE_ARCHIVE_PATH="$SNAPSHOT_PATH/$SITE_DOMAIN-$SNAPSHOT_TIMESTAMP.tar.gz"
SQL_ARCHIVE_PATH="$SNAPSHOT_PATH/$SITE_DOMAIN-$SNAPSHOT_TIMESTAMP.sql.gz"

echo tar zcf "$FILE_ARCHIVE_PATH" .
echo $MYSQLDUMP_COMMAND '|' gzip '>' "$SQL_ARCHIVE_PATH"

