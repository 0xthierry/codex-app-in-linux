# Codex.dmg On Linux

Runs the macOS `Codex.dmg` desktop app on Linux by:

- extracting the app payload from the DMG
- launching it with a pinned Linux Electron runtime
- rebuilding `better-sqlite3` for Linux/Electron
- wiring the app to a Linux Codex CLI binary

## What This Repo Needs

- Linux with `git-lfs`, `7z`, `node`, `npm`, `gcc`, `make`, and `python3`

## Clone

```bash
git lfs install
git clone <repo-url>
cd codex-app-in-linux
git lfs pull
```

`assets/Codex.dmg` is stored through Git LFS. Without `git-lfs`, the repo checkout contains only a small pointer file and the launcher will not work.

## Run From The Repo

```bash
./run-codex-linux.sh
```

The DMG is already expected to live in `assets/` as part of the repo. The first launch bootstraps `.codex-linux-runtime/` and may take a while. Later launches reuse the cached runtime.

## Install As A Desktop App

```bash
./install.sh
```

This installs the app for the current user:

- repo payload into `~/.local/opt/codex-app-in-linux`
- launcher into `~/.local/bin/codex-linux`
- desktop entry into `~/.local/share/applications/codex-linux.desktop`
- icon into `~/.local/share/icons/hicolor/512x512/apps/codex-linux.png`
- runtime cache into `~/.local/state/codex-app-in-linux/runtime`

After that, launch `Codex` from your desktop app menu or run:

```bash
codex-linux
```

To remove the installed app:

```bash
~/.local/bin/codex-linux-uninstall
```

## Repository Layout

- `assets/Codex.dmg`: the macOS app image used as input
- `assets/codex-linux.png`: icon extracted from the macOS app bundle and used by the installer
- `install.sh`: per-user installer that registers the app in the desktop menu
- `linux-tools/`: pinned Linux-side toolchain and lockfile
- `runner/`: small Electron wrapper that makes the DMG payload boot on Linux
- `uninstall.sh`: removes the per-user install
- `docs/process.md`: explanation of the reverse-engineering and bootstrapping process

## Overrides

- `CODEX_CLI_PATH`: use a specific Linux Codex CLI executable instead of the pinned local one
- `CODEX_RG_PATH`: use a specific `rg` binary instead of the detected one
- `CODEX_LINUX_RUNTIME_DIR`: move the generated runtime/cache directory somewhere else

## Notes

- The repo does not build a native Linux Codex desktop app. It adapts the macOS DMG payload to a Linux runtime.
- The launcher is currently tested on Arch Linux.
- `.codex-linux-runtime/`, `linux-tools/node_modules/`, and `ai_docs/` are ignored by git.
