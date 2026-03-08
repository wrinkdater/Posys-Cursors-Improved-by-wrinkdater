#!/bin/sh

# 1. Validation and Setup
if [ -z "$1" ]; then
    echo "no folder provided"
    exit 1
fi

THEME_NAME="$1"
CURSOR_SIZE=64
ICON_DIR="$HOME/.icons"
XDG_ICON_DIR="$HOME/.local/share/icons"
TARGET_DIR="linux/$THEME_NAME"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR not found."
    exit 1
fi

# 2. Install Theme to Standard Locations
mkdir -p "$ICON_DIR" "$XDG_ICON_DIR"
cp -r "$TARGET_DIR" "$ICON_DIR/"
cp -r "$TARGET_DIR" "$XDG_ICON_DIR/"

# 3. GNOME / GTK (Wayland)
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME_NAME"
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"
fi
# 4. KDE Plasma (5 or 6)

if command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme "$THEME_NAME"
    kwriteconfig5 --file kcminputrc --group Mouse --key cursorSize "$CURSOR_SIZE"
    qdbus5 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
elif command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$THEME_NAME"
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$CURSOR_SIZE"
    dbus-send --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1
fi

# 5. XDG/Inheritance for wlroots & XWayland
# This forces apps that don't read D-Bus to look at the 'default' folder
mkdir -p "$ICON_DIR/default"
cat <<EOF > "$ICON_DIR/default/index.theme"
[Icon Theme]
Inherits=$THEME_NAME
EOF

# 6. XWayland Compatibility
echo "Xcursor.theme: $THEME_NAME" >> ~/.Xresources
echo "Xcursor.size: $CURSOR_SIZE" >> ~/.Xresources
command -v xrdb >/dev/null 2>&1 && xrdb -merge ~/.Xresources

# 7. Flatpak Overrides
if command -v flatpak >/dev/null 2>&1; then
    flatpak override --user --filesystem=~/.icons:ro
    flatpak override --user --env=XCURSOR_THEME="$THEME_NAME" --env=XCURSOR_SIZE="$CURSOR_SIZE"
fi

# 8. Environment Variables (The "Safety Net")
echo "Success: Theme '$THEME_NAME' installed and configured."
echo ""
echo -e "\033[1;5;33mMANUAL ACTION REQUIRED\033[0m"
echo "Add the following lines to your shell's configuration file"
echo "-------------------------------------------------------"
echo "export XCURSOR_THEME=$THEME_NAME"
echo "export XCURSOR_SIZE=$CURSOR_SIZE"
echo "-------------------------------------------------------"
