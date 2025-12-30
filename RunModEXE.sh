#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-exe> [exe-args...]"
    exit 1
fi

EXE_PATH="$1"
shift
EXE_ARGS=("$@")

if ! command -v protontricks-launch >/dev/null 2>&1; then
    echo "Error: protontricks-launch not found in PATH."
    exit 1
fi

START_DIR="$(pwd)"

# Locate Steam library root
STEAMLIB=""
SEARCH_DIR="$START_DIR"

while [[ "$SEARCH_DIR" != "/" ]]; do
    if [[ -d "$SEARCH_DIR/steamapps" ]]; then
        STEAMLIB="$SEARCH_DIR"
        break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [[ -z "$STEAMLIB" ]]; then
    echo "Error: Could not locate Steam library root."
    exit 1
fi

STEAMAPPS="$STEAMLIB/steamapps"

mapfile -t MANIFESTS < <(ls "$STEAMAPPS"/appmanifest_*.acf 2>/dev/null)

APPID=""
GAME_ROOT=""
CHECK_DIR="$START_DIR"

while [[ "$CHECK_DIR" != "/" ]]; do
    DIR_BASENAME="$(basename "$CHECK_DIR")"

    for MANIFEST in "${MANIFESTS[@]}"; do
        INSTALLDIR=$(grep -m1 '"installdir"' "$MANIFEST" \
            | sed -E 's/.*"installdir"[[:space:]]+"([^"]+)".*/\1/')

        if [[ "$INSTALLDIR" == "$DIR_BASENAME" ]]; then
            APPID="$(basename "$MANIFEST" | sed 's/appmanifest_\(.*\)\.acf/\1/')"
            GAME_ROOT="$CHECK_DIR"
            break 2
        fi
    done

    CHECK_DIR="$(dirname "$CHECK_DIR")"
done

if [[ -z "$APPID" ]]; then
    echo "Error: Could not determine AppID."
    exit 1
fi

echo "$APPID" > "$GAME_ROOT/appid.txt"

PREFIX="$STEAMAPPS/compatdata/$APPID/pfx"
if [[ ! -d "$PREFIX" ]]; then
    echo "Error: Proton prefix not found."
    exit 1
fi

if [[ ! -f "$EXE_PATH" ]]; then
    echo "Error: Executable not found: $EXE_PATH"
    exit 1
fi

# ---- Static launcher generation ----

EXE_DIR="$(cd "$(dirname "$EXE_PATH")" && pwd)"
EXE_NAME="$(basename "$EXE_PATH")"
SCRIPT_NAME="${EXE_NAME%.*}.sh"
SCRIPT_PATH="$EXE_DIR/$SCRIPT_NAME"

cat > "$SCRIPT_PATH" <<EOF
#!/usr/bin/env bash
exec protontricks-launch --appid $APPID "\$(dirname "\$0")/$EXE_NAME" "\$@"
EOF

chmod +x "$SCRIPT_PATH"

echo "Detected AppID: $APPID"
echo "Game root: $GAME_ROOT"
echo "Saved AppID to: $GAME_ROOT/appid.txt"
echo "Generated static launcher: $SCRIPT_PATH"

# ---- Immediate launch ----

exec protontricks-launch --appid "$APPID" "$EXE_PATH" "${EXE_ARGS[@]}"
