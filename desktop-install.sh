#!/bin/bash

# Sets variables
PREFIX="$HOME"
DESKTOP_DIR="$HOME/Desktop"
APP_DIR="$PREFIX/.local/share/Overclock-Manager"
ZIP_URL="https://github.com/Taskerer/Overclock-Manager/releases/latest/download/Overclock-Manager.zip"

cd "$PREFIX" || exit 1
rm -rf "$APP_DIR" "$HOME/Overclock-Manager.zip"

# Downloading and unpacking
wget "$ZIP_URL" -O Overclock-Manager.zip || {
  zenity --error --text="Failed to download Overclock Manager!" --width=300
  exit 1
}

unzip Overclock-Manager.zip -d "$PREFIX/.local/share/" || {
  zenity --error --text="Failed to unpack the archive!" --width=300
  exit 1
}
rm -f Overclock-Manager.zip

# Creating a sturtup shortcut
cat <<EOF >"$DESKTOP_DIR/Overclock-Manager.desktop"
[Desktop Entry]
Categories=Settings
Comment=Overclock Manager For Steam Deck by SDWEAK
Exec=./Overclock-Manager.sh
Icon=flatpak-discover
Name=Overclock Manager
Path=$APP_DIR
StartupNotify=false
Terminal=true
Type=Application
Version=1.0
EOF
chmod +x "$DESKTOP_DIR/Overclock-Manager.desktop"

# Notification of successful instalation
zenity --info --text="Overclock Manager has been successfully downloaded and installed!"
