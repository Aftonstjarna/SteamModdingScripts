#!/bin/bash

# Script to open Steam game's compatdata steamuser folder in split view
# Run this from within a Steam game's installation folder

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎮 Steam Prefix Finder (Split View)${NC}"
echo "=========================="

# Find appmanifest file and game root by looking up the directory tree
find_appid_and_game_root() {
    local current_dir="$PWD"
    
    # First, traverse up to find steamapps/common
    local search_dir="$current_dir"
    while [[ "$search_dir" != "/" ]]; do
        # Check if we're anywhere under steamapps/common
        if [[ "$search_dir" == */steamapps/common/* ]]; then
            # Extract the path up to and including steamapps
            local steamapps_dir="${search_dir%%/common/*}"
            
            # Get everything after steamapps/common/
            local path_after_common="${search_dir#*/steamapps/common/}"
            
            # Extract just the game folder name (first component after common/)
            local game_folder="${path_after_common%%/*}"
            
            # Build the full game root path
            local game_root="$steamapps_dir/common/$game_folder"
            
            # Search for appmanifest files
            for manifest in "$steamapps_dir"/appmanifest_*.acf; do
                if [[ -f "$manifest" ]]; then
                    # Check if this manifest references our game folder
                    if grep -q "\"installdir\".*\"${game_folder}\"" "$manifest" 2>/dev/null; then
                        # Extract AppID from filename
                        local appid="${manifest##*/appmanifest_}"
                        appid="${appid%.acf}"
                        echo "$appid|$game_root"
                        return 0
                    fi
                fi
            done
            
            # If we found steamapps/common but no matching manifest, keep looking up
        fi
        search_dir="$(dirname "$search_dir")"
    done
    
    return 1
}

# Detect file manager
detect_file_manager() {
    if command -v dolphin &> /dev/null; then
        echo "dolphin"
    elif command -v nautilus &> /dev/null; then
        echo "nautilus"
    elif command -v nemo &> /dev/null; then
        echo "nemo"
    elif command -v thunar &> /dev/null; then
        echo "thunar"
    elif command -v caja &> /dev/null; then
        echo "caja"
    elif command -v xdg-open &> /dev/null; then
        echo "xdg-open"
    else
        echo ""
    fi
}

# Open in split view using xdotool for Dolphin
open_dolphin_split() {
    local game_folder="$1"
    local prefix_folder="$2"
    
    # Check if xdotool is available
    if ! command -v xdotool &> /dev/null; then
        echo -e "${YELLOW}⚠ xdotool not found, opening in new tabs instead${NC}"
        echo -e "${YELLOW}Install xdotool for proper split view support${NC}"
        dolphin "$game_folder" "$prefix_folder" &> /dev/null &
        return
    fi
    
    # Find existing Dolphin window
    local dolphin_service=$(qdbus 2>/dev/null | grep -m1 "org.kde.dolphin")
    
    if [[ -n "$dolphin_service" ]]; then
        echo -e "${BLUE}Using existing Dolphin window${NC}"
        
        # Get the Dolphin window ID
        local window_id=$(xdotool search --class "dolphin" | head -n1)
        
        if [[ -n "$window_id" ]]; then
            # Focus the window
            xdotool windowactivate "$window_id"
            sleep 0.2
            
            # Navigate to game folder (Ctrl+L to focus location bar, then type path)
            xdotool key ctrl+l
            sleep 0.1
            xdotool type "$game_folder"
            sleep 0.1
            xdotool key Return
            sleep 0.3
            
            # Enable split view (F3 in Dolphin)
            xdotool key F3
            sleep 0.3
            
            # Switch to right pane (Tab)
            xdotool key Tab
            sleep 0.1
            
            # Navigate to prefix folder
            xdotool key ctrl+l
            sleep 0.1
            xdotool type "$prefix_folder"
            sleep 0.1
            xdotool key Return
            
            echo -e "${GREEN}✓ Split view configured!${NC}"
        else
            echo -e "${YELLOW}Could not find Dolphin window, opening new one${NC}"
            dolphin "$game_folder" &> /dev/null &
            sleep 0.8
            
            window_id=$(xdotool search --class "dolphin" | tail -n1)
            if [[ -n "$window_id" ]]; then
                xdotool windowactivate "$window_id"
                sleep 0.2
                xdotool key F3
                sleep 0.3
                xdotool key Tab
                sleep 0.1
                xdotool key ctrl+l
                sleep 0.1
                xdotool type "$prefix_folder"
                xdotool key Return
            fi
        fi
    else
        echo -e "${YELLOW}No existing Dolphin window found, opening new one${NC}"
        dolphin "$game_folder" &> /dev/null &
        sleep 0.8
        
        local window_id=$(xdotool search --class "dolphin" | tail -n1)
        if [[ -n "$window_id" ]]; then
            xdotool windowactivate "$window_id"
            sleep 0.2
            xdotool key F3
            sleep 0.3
            xdotool key Tab
            sleep 0.1
            xdotool key ctrl+l
            sleep 0.1
            xdotool type "$prefix_folder"
            xdotool key Return
        fi
    fi
}

# Open in split view
open_split_view() {
    local game_folder="$1"
    local prefix_folder="$2"
    local fm="$3"
    
    case "$fm" in
        dolphin)
            open_dolphin_split "$game_folder" "$prefix_folder"
            ;;
        nautilus)
            # Nautilus doesn't support split view natively, open both windows
            nautilus "$game_folder" &> /dev/null &
            sleep 0.3
            nautilus "$prefix_folder" &> /dev/null &
            ;;
        nemo)
            # Nemo doesn't support split view, open both windows
            nemo "$game_folder" &> /dev/null &
            sleep 0.3
            nemo "$prefix_folder" &> /dev/null &
            ;;
        thunar)
            # Thunar doesn't support split view, open both windows
            thunar "$game_folder" &> /dev/null &
            sleep 0.3
            thunar "$prefix_folder" &> /dev/null &
            ;;
        caja)
            # Caja doesn't support split view, open both windows
            caja "$game_folder" &> /dev/null &
            sleep 0.3
            caja "$prefix_folder" &> /dev/null &
            ;;
        *)
            xdg-open "$game_folder" &> /dev/null &
            sleep 0.3
            xdg-open "$prefix_folder" &> /dev/null &
            ;;
    esac
}

# Main logic
RESULT=$(find_appid_and_game_root)

if [[ -z "$RESULT" ]]; then
    echo -e "${RED}❌ Could not detect AppID${NC}"
    echo "Make sure you're running this script from within a Steam game folder"
    echo "Expected path: .../steamapps/common/GameName/ (or any subfolder)"
    exit 1
fi

# Split result
APPID="${RESULT%%|*}"
GAME_ROOT="${RESULT##*|}"

echo -e "${GREEN}✓ Found AppID:${NC} $APPID"
echo -e "${BLUE}Game Folder:${NC} $GAME_ROOT"

# Find Steam root directory
STEAM_ROOT=""
current_dir="$GAME_ROOT"
while [[ "$current_dir" != "/" ]]; do
    parent_dir="$(dirname "$current_dir")"
    if [[ -d "$parent_dir/steamapps" ]]; then
        STEAM_ROOT="$parent_dir"
        break
    fi
    current_dir="$parent_dir"
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

echo -e "${BLUE}File Manager:${NC} $FILE_MANAGER"

# Open folders based on file manager capabilities
if [[ "$FILE_MANAGER" == "dolphin" ]]; then
    echo -e "${GREEN}✓ Opening in split view...${NC}"
    echo -e "${YELLOW}Left:${NC} $GAME_ROOT"
    echo -e "${YELLOW}Right:${NC} $STEAMUSER_PATH"
    open_split_view "$GAME_ROOT" "$STEAMUSER_PATH" "$FILE_MANAGER"
elif [[ "$FILE_MANAGER" == "nautilus" || "$FILE_MANAGER" == "nemo" || "$FILE_MANAGER" == "thunar" || "$FILE_MANAGER" == "caja" ]]; then
    echo -e "${GREEN}✓ Opening dual windows...${NC}"
    echo -e "${YELLOW}Window 1:${NC} $GAME_ROOT"
    echo -e "${YELLOW}Window 2:${NC} $STEAMUSER_PATH"
    open_split_view "$GAME_ROOT" "$STEAMUSER_PATH" "$FILE_MANAGER"
else
    echo -e "${GREEN}✓ Opening prefix folder...${NC}"
    echo -e "${YELLOW}Path:${NC} $STEAMUSER_PATH"
    "$FILE_MANAGER" "$STEAMUSER_PATH" &> /dev/null &
fi

echo -e "${GREEN}✓ Done!${NC}"
