#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${CODEX_LINUX_INSTALL_DIR:-$HOME/.local/opt/codex-app-in-linux}"
BIN_DIR="${CODEX_LINUX_BIN_DIR:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
APPLICATIONS_DIR="$DATA_DIR/applications"
ICON_DIR="$DATA_DIR/icons/hicolor/512x512/apps"
DESKTOP_FILE="$APPLICATIONS_DIR/codex-linux.desktop"
ICON_PATH="$ICON_DIR/codex-linux.png"
LAUNCHER_PATH="$BIN_DIR/codex-linux"
UNINSTALLER_PATH="$BIN_DIR/codex-linux-uninstall"
STATE_ROOT="$STATE_DIR/codex-app-in-linux"

rm -f "$DESKTOP_FILE" "$ICON_PATH" "$LAUNCHER_PATH" "$UNINSTALLER_PATH"
rm -rf "$INSTALL_DIR" "$STATE_ROOT"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

printf 'Removed Codex Linux install from this user profile.\n'
