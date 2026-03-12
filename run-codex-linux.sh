#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${CODEX_LINUX_RUNTIME_DIR:-$ROOT_DIR/.codex-linux-runtime}"
DMG_EXTRACT_DIR="$RUNTIME_DIR/dmg"
APP_ROOT="$RUNTIME_DIR/app"
TOOLS_DIR="$ROOT_DIR/linux-tools"
TOOLS_NODE_MODULES="$TOOLS_DIR/node_modules"
ELECTRON_DIST="$TOOLS_NODE_MODULES/electron/dist"
ASAR_BIN="$TOOLS_NODE_MODULES/.bin/asar"
DMG_PATH="$ROOT_DIR/assets/Codex.dmg"
DMG_RESOURCES_DIR="$DMG_EXTRACT_DIR/Codex Installer/Codex.app/Contents/Resources"
APP_SQLITE_NODE="$APP_ROOT/node_modules/better-sqlite3/build/Release/better_sqlite3.node"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

need_cmd 7z
need_cmd npm
need_cmd node
need_cmd gcc
need_cmd make
need_cmd python3

if [[ ! -f "$DMG_PATH" ]]; then
  printf 'Missing DMG: %s\n' "$DMG_PATH" >&2
  exit 1
fi

if sed -n '1p' "$DMG_PATH" | grep -qx 'version https://git-lfs.github.com/spec/v1'; then
  printf 'assets/Codex.dmg is a Git LFS pointer, not the real DMG payload.\n' >&2
  printf 'Install git-lfs, then run: git lfs pull\n' >&2
  exit 1
fi

mkdir -p "$RUNTIME_DIR"
installed_tools=0

if [[ ! -x "$ELECTRON_DIST/electron" || ! -x "$TOOLS_NODE_MODULES/.bin/codex" || ! -x "$ASAR_BIN" ]]; then
  printf 'Installing pinned Linux toolchain...\n'
  npm ci --prefix "$TOOLS_DIR" >/dev/null
  installed_tools=1
fi

ELECTRON_VERSION="$(
  node -p "require(process.argv[1]).version" \
    "$TOOLS_NODE_MODULES/electron/package.json"
)"
SQLITE_MARKER="$RUNTIME_DIR/.better-sqlite3-linux-ready-${ELECTRON_VERSION//./_}"

LOCAL_CODEX_BIN="$TOOLS_NODE_MODULES/.bin/codex"
LOCAL_RG_BIN="$(
  find "$TOOLS_NODE_MODULES" -path '*/vendor/*/path/rg' -type f 2>/dev/null | head -n 1
)"

CODEX_BIN="${CODEX_CLI_PATH:-${LOCAL_CODEX_BIN}}"
RG_BIN="${CODEX_RG_PATH:-${LOCAL_RG_BIN:-$(command -v rg || true)}}"

if [[ -z "${CODEX_BIN}" || ! -f "${CODEX_BIN}" ]]; then
  printf 'Could not locate a Linux Codex CLI. Set CODEX_CLI_PATH to a working codex executable.\n' >&2
  exit 1
fi

if [[ -z "${RG_BIN}" || ! -f "${RG_BIN}" ]]; then
  printf 'Could not locate rg. Set CODEX_RG_PATH to a working ripgrep executable.\n' >&2
  exit 1
fi

if [[ ! -d "$APP_ROOT/.vite" ]]; then
  printf 'Extracting Codex.dmg...\n'
  rm -rf "$DMG_EXTRACT_DIR" "$APP_ROOT"
  mkdir -p "$DMG_EXTRACT_DIR"
  7z x -o"$DMG_EXTRACT_DIR" "$DMG_PATH" >/dev/null
  "$ASAR_BIN" extract "$DMG_RESOURCES_DIR/app.asar" "$APP_ROOT"
fi

if [[ "$installed_tools" -eq 1 ]]; then
  rm -f "$RUNTIME_DIR"/.better-sqlite3-linux-ready-*
fi

if [[ ! -f "$SQLITE_MARKER" ]]; then
  printf 'Building Linux better-sqlite3 module...\n'
  # npm/node-gyp on this toolchain can fail during post-build cleanup if this
  # helper directory is absent, even after the Electron ABI build succeeds.
  mkdir -p "$TOOLS_NODE_MODULES/better-sqlite3/build/node_gyp_bins"
  npm_config_runtime=electron \
  npm_config_target="$ELECTRON_VERSION" \
  npm_config_disturl=https://electronjs.org/headers \
  npm rebuild --prefix "$TOOLS_DIR" better-sqlite3 >/dev/null
  touch "$SQLITE_MARKER"
fi

cp "$TOOLS_NODE_MODULES/better-sqlite3/build/Release/better_sqlite3.node" "$APP_SQLITE_NODE"

mkdir -p "$ELECTRON_DIST/resources/bin" "$ROOT_DIR/runner/resources/bin"
ln -sf "$CODEX_BIN" "$ELECTRON_DIST/resources/bin/codex"
ln -sf "$RG_BIN" "$ELECTRON_DIST/resources/rg"
ln -sf "$CODEX_BIN" "$ROOT_DIR/runner/resources/bin/codex"
ln -sf "$RG_BIN" "$ROOT_DIR/runner/resources/rg"

export CODEX_APP_ROOT="$APP_ROOT"
export CODEX_CLI_PATH="$CODEX_BIN"

exec "$ELECTRON_DIST/electron" "$ROOT_DIR/runner" "$@"
