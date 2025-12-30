# Proton Prefix Opener
When placed in the game folder it detects the proton prefix and opens in in Dolphin file manager


# Proton Static Launcher Generator

## Overview

This script is a utility for Steam games running under Proton on Linux. It detects the Steam AppID associated with the current game directory, even when executed from a subdirectory, and uses `protontricks-launch` to run a specified Windows executable. After detection, it generates a static launcher script for that executable so it can be run directly in the future without repeating AppID detection.

The generated launcher hardcodes the AppID and can be reused indefinitely.

## Key Features

- Automatically detects the Steam AppID by reading `appmanifest_*.acf` files
- Works when executed from any subdirectory inside a game installation
- Supports multiple Steam library locations
- Saves the detected AppID to `appid.txt` in the game root
- Generates a reusable static launcher script next to the target EXE
- Uses `protontricks-launch --appid` for correct Proton prefix handling

## Requirements

- Linux system with Steam installed
- Proton enabled for the target game
- `protontricks` installed and available in PATH
- Bash shell

## Installation

1. Download or copy the script to a location of your choice.
2. Mark the script as executable.

```bash
chmod +x proton_run_from_any_subdir.sh
```

3. Ensure `protontricks-launch` is available.

```bash
which protontricks-launch
```

## Usage

1. Change directory to any location inside the game installation directory.

```bash
cd ~/.steam/steam/steamapps/common/MyGame/bin/win64
```

2. Run the script with the Windows executable and any optional arguments.

```bash
/path/to/proton_run_from_any_subdir.sh Launcher.exe --optional-args
```

## What the Script Does

1. Walks upward from the current working directory to locate the Steam library root.
2. Reads Steam app manifest files to identify the matching game directory.
3. Extracts the Steam AppID from the corresponding manifest.
4. Writes the AppID to `appid.txt` in the game root directory.
5. Confirms the Proton prefix exists for the detected AppID.
6. Generates a static launcher script next to the specified EXE.
7. Launches the EXE immediately using `protontricks-launch`.

## Generated Static Launcher

If the target executable is:

```text
Launcher.exe
```

The script generates a launcher named:

```text
Launcher.sh
```

in the same directory.

The generated launcher contains:

```bash
#!/usr/bin/env bash
exec protontricks-launch --appid 123456 "$(dirname "$0")/Launcher.exe" "$@"
```

This launcher can be executed directly without repeating AppID detection.

## Files Created

- `appid.txt`  
  Contains the numeric Steam AppID. Stored in the game root directory.

- `<ExecutableName>.sh`  
  Static launcher script generated next to the Windows executable.

## Notes and Limitations

- The game must have been launched at least once so the Proton prefix exists.
- The script assumes a standard Steam directory layout using `steamapps`.
- If multiple Steam libraries contain games with identical directory names, the first match is used.
- If a launcher script with the same name already exists, it will be overwritten.
- Flatpak Steam installations are not explicitly handled.

## Typical Use Cases

- Running game configuration utilities shipped as Windows executables
- Launching mod tools inside Proton prefixes
- Creating stable launchers for mod managers and external tooling
- Adding custom Proton tools to desktop entries or scripts

## License

This script is provided as is, without warranty of any kind. You are free to use, modify, and redistribute it for any purpose.
