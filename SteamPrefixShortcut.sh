#!/usr/bin/env bash
set -euo pipefail

# Resolve current directory
GAME_DIR="$(realpath "$PWD")"

# Walk upward to find steamapps/common
SEARCH_DIR="$GAME_DIR"
while [[ "$SEARCH_DIR" != "/" ]]; do
    if [[ "$(basename "$SEARCH_DIR")" == "common" && \
          "$(basename "$(dirname "$SEARCH_DIR")")" == "steamapps" ]]; then
        STEAMAPPS_DIR="$(dirname "$SEARCH_DIR")"
        break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [[ -z "${STEAMAPPS_DIR:-}" ]]; then
    echo "Error: Not inside a Steam steamapps/common directory."
    exit 1
fi

LIBRARY_DIR="$(dirname "$STEAMAPPS_DIR")"
COMMON_DIR="$STEAMAPPS_DIR/common"

# Identify the game folder name
GAME_FOLDER="$(basename "$GAME_DIR")"

# Find matching AppID via appmanifest files
APPID=""
for manifest in "$STEAMAPPS_DIR"/appmanifest_*.acf; do
    if grep -q "\"installdir\"[[:space:]]*\"$GAME_FOLDER\"" "$manifest"; then
        APPID="$(basename "$manifest" | sed 's/appmanifest_//' | sed 's/\.acf//')"
        break
    fi
done

if [[ -z "$APPID" ]]; then
    echo "Error: Could not determine AppID for $GAME_FOLDER"
    exit 1
fi

PREFIX_PATH="$STEAMAPPS_DIR/compatdata/$APPID/pfx/drive_c/users/steamuser"

if [[ ! -d "$PREFIX_PATH" ]]; then
    echo "Error: Proton prefix not found (game may not have been run yet)."
    exit 1
fi

# Open in Dolphin
dolphin "$PREFIX_PATH" >/dev/null 2>&1 &
