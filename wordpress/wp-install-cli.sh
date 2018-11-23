#!/bin/bash

SCRIPT_PATH="${BASH_SOURCE[0]}"
[ -h "$SCRIPT_PATH" ] && SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)" || exit 2

. "$SCRIPT_DIR/common"

check_not_root

# only attempt to update if WP-CLI is already installed
check_wp_cli && update_wp_cli

