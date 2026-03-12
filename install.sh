#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${CODEX_LINUX_INSTALL_DIR:-$HOME/.local/opt/codex-app-in-linux}"
BIN_DIR="${CODEX_LINUX_BIN_DIR:-$HOME/.local/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
APPLICATIONS_DIR="$DATA_DIR/applications"
ICON_DIR="$DATA_DIR/icons/hicolor/512x512/apps"
DESKTOP_FILE="$APPLICATIONS_DIR/codex-linux.desktop"
ICON_SOURCE="$ROOT_DIR/assets/codex-linux.png"
ICON_TARGET="$ICON_DIR/codex-linux.png"
LEGACY_ICON_PATH="$DATA_DIR/icons/hicolor/scalable/apps/codex-linux.svg"
LAUNCHER_PATH="$BIN_DIR/codex-linux"
UNINSTALLER_PATH="$BIN_DIR/codex-linux-uninstall"
RUNTIME_DIR="$STATE_DIR/codex-app-in-linux/runtime"
TMP_DIR="${INSTALL_DIR}.tmp"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

need_cmd tar

if [[ ! -f "$ROOT_DIR/assets/Codex.dmg" ]]; then
  printf 'Missing DMG: %s/assets/Codex.dmg\n' "$ROOT_DIR" >&2
  exit 1
fi

if sed -n '1p' "$ROOT_DIR/assets/Codex.dmg" | grep -qx 'version https://git-lfs.github.com/spec/v1'; then
  printf 'assets/Codex.dmg is a Git LFS pointer, not the real DMG payload.\n' >&2
  printf 'Install git-lfs, then run: git lfs pull\n' >&2
  exit 1
fi

mkdir -p "$BIN_DIR" "$APPLICATIONS_DIR" "$ICON_DIR" "$STATE_DIR/codex-app-in-linux"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

tar \
  --exclude=.git \
  --exclude=.codex-linux-runtime \
  --exclude=linux-tools/node_modules \
  --exclude=ai_docs \
  --exclude=runner/resources \
  -C "$ROOT_DIR" \
  -cf - \
  . | tar -C "$TMP_DIR" -xf -

rm -rf "$INSTALL_DIR"
mv "$TMP_DIR" "$INSTALL_DIR"

rm -f "$LEGACY_ICON_PATH"
install -m 0644 "$ICON_SOURCE" "$ICON_TARGET"

cat >"$LAUNCHER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export CODEX_LINUX_RUNTIME_DIR="$RUNTIME_DIR"
exec "$INSTALL_DIR/run-codex-linux.sh" "\$@"
EOF
chmod +x "$LAUNCHER_PATH"

cat >"$UNINSTALLER_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$INSTALL_DIR/uninstall.sh"
EOF
chmod +x "$UNINSTALLER_PATH"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Codex
Comment=Run Codex on Linux from the packaged DMG bootstrap
Exec=$LAUNCHER_PATH %U
Icon=codex-linux
Terminal=false
Categories=Development;
StartupNotify=true
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$DATA_DIR/icons/hicolor" >/dev/null 2>&1 || true
fi

if command -v xdg-icon-resource >/dev/null 2>&1; then
  xdg-icon-resource forceupdate >/dev/null 2>&1 || true
fi

printf 'Installed Codex for this user.\n'
printf 'Launcher: %s\n' "$LAUNCHER_PATH"
printf 'Desktop entry: %s\n' "$DESKTOP_FILE"
printf 'App data: %s\n' "$INSTALL_DIR"
