#!/bin/bash

# Script to open Steam game's compatdata steamuser folder
# Run this from within a Steam game's installation folder

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎮 Steam Prefix Finder${NC}"
echo "=========================="
echo "Run from game folder or any subfolder within"
echo ""

# Find appmanifest file by looking up the directory tree
find_appid() {
    local current_dir="$PWD"
    local game_folder=""
    local steamapps_dir=""
    
    # Walk up the directory tree to find steamapps/common
    while [[ "$current_dir" != "/" ]]; do
        # Check if we're in or under steamapps/common
        if [[ "$current_dir" == */steamapps/common/* ]] || [[ "$current_dir" == */steamapps/common ]]; then
            # Extract the steamapps directory
            if [[ "$current_dir" == */steamapps/common/* ]]; then
                steamapps_dir="${current_dir%%/common/*}"
                # Get everything after /common/
                local after_common="${current_dir#*/common/}"
                # Extract just the game folder name (first directory after common/)
                game_folder="${after_common%%/*}"
            elif [[ "$current_dir" == */steamapps/common ]]; then
                # We're exactly in the common folder, can't determine game
                current_dir="$(dirname "$current_dir")"
                continue
            fi
            
            # Search for appmanifest files
            for manifest in "$steamapps_dir"/appmanifest_*.acf; do
                if [[ -f "$manifest" ]]; then
                    # Extract installdir from manifest and compare
                    local installdir=$(grep -i "\"installdir\"" "$manifest" | sed 's/.*"\([^"]*\)"[^"]*$/\1/' | tr -d '\r\n\t ')
                    
                    # Case-insensitive comparison
                    if [[ "${installdir,,}" == "${game_folder,,}" ]]; then
                        # Extract AppID from filename
                        local appid="${manifest##*/appmanifest_}"
                        appid="${appid%.acf}"
                        echo "$appid"
                        return 0
                    fi
                fi
            done
            
            # If we found steamapps but no match, something's wrong
            if [[ -n "$steamapps_dir" ]]; then
                return 1
            fi
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    return 1
}

# Detect file manager
detect_file_manager() {
    if command -v xdg-open &> /dev/null; then
        echo "xdg-open"
    elif command -v nautilus &> /dev/null; then
        echo "nautilus"
    elif command -v dolphin &> /dev/null; then
        echo "dolphin"
    elif command -v thunar &> /dev/null; then
        echo "thunar"
    elif command -v nemo &> /dev/null; then
        echo "nemo"
    elif command -v caja &> /dev/null; then
        echo "caja"
    else
        echo ""
    fi
}

# Main logic
APPID=$(find_appid)

if [[ -z "$APPID" ]]; then
    echo -e "${RED}❌ Could not detect AppID${NC}"
    echo "Make sure you're running this script from within a Steam game folder"
    echo "Expected path: .../steamapps/common/GameName/"
    exit 1
fi

echo -e "${GREEN}✓ Found AppID:${NC} $APPID"

# Find Steam root directory
STEAM_ROOT=""
current_dir="$PWD"
while [[ "$current_dir" != "/" ]]; do
    if [[ -d "$current_dir/steamapps" ]]; then
        STEAM_ROOT="$current_dir"
        break
    fi
    current_dir="$(dirname "$current_dir")"
done

if [[ -z "$STEAM_ROOT" ]]; then
    echo -e "${RED}❌ Could not find Steam root directory${NC}"
    exit 1
fi

# Build compatdata path
COMPATDATA_PATH="$STEAM_ROOT/steamapps/compatdata/$APPID"
STEAMUSER_PATH="$COMPATDATA_PATH/pfx/drive_c/users/steamuser"

echo -e "${YELLOW}Steam Root:${NC} $STEAM_ROOT"
echo -e "${YELLOW}Compatdata Path:${NC} $COMPATDATA_PATH"

# Check if compatdata exists
if [[ ! -d "$COMPATDATA_PATH" ]]; then
    echo -e "${RED}❌ Compatdata folder not found${NC}"
    echo "This game might not use Proton/Wine compatibility layer"
    exit 1
fi

# Check if steamuser folder exists
if [[ ! -d "$STEAMUSER_PATH" ]]; then
    echo -e "${YELLOW}⚠ steamuser folder not found, opening compatdata root instead${NC}"
    STEAMUSER_PATH="$COMPATDATA_PATH"
fi

# Detect and use file manager
FILE_MANAGER=$(detect_file_manager)

if [[ -z "$FILE_MANAGER" ]]; then
    echo -e "${RED}❌ No GUI file manager found${NC}"
    echo -e "${YELLOW}Path:${NC} $STEAMUSER_PATH"
    exit 1
fi

echo -e "${GREEN}✓ Opening in file manager...${NC}"
echo -e "${YELLOW}Path:${NC} $STEAMUSER_PATH"

# Open the folder
"$FILE_MANAGER" "$STEAMUSER_PATH" &> /dev/null &

echo -e "${GREEN}✓ Done!${NC}"
