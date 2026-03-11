# Codex.dmg On Linux

Runs the macOS `Codex.dmg` desktop app on Linux by:

- extracting the app payload from the DMG
- launching it with a pinned Linux Electron runtime
- rebuilding `better-sqlite3` for Linux/Electron
- wiring the app to a Linux Codex CLI binary

## What This Repo Needs

- Linux with `7z`, `node`, `npm`, `gcc`, `make`, and `python3`

## Usage

```bash
git clone <repo-url>
cd codex-app-in-linux
./run-codex-linux.sh
```

The DMG is already expected to live in `assets/` as part of the repo. The first launch bootstraps `.codex-linux-runtime/` and may take a while. Later launches reuse the cached runtime.

## Repository Layout

- `assets/Codex.dmg`: the macOS app image used as input
- `linux-tools/`: pinned Linux-side toolchain and lockfile
- `runner/`: small Electron wrapper that makes the DMG payload boot on Linux
- `docs/process.md`: explanation of the reverse-engineering and bootstrapping process

## Overrides

- `CODEX_CLI_PATH`: use a specific Linux Codex CLI executable instead of the pinned local one
- `CODEX_RG_PATH`: use a specific `rg` binary instead of the detected one

## Notes

- The repo does not build a native Linux Codex desktop app. It adapts the macOS DMG payload to a Linux runtime.
- The launcher is currently tested on Arch Linux.
- `.codex-linux-runtime/`, `linux-tools/node_modules/`, and `ai_docs/` are ignored by git.
