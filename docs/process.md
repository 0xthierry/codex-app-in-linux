# Process

This document explains how the macOS `Codex.dmg` was made runnable on Linux.

## Goal

Run the desktop app payload from `Codex.dmg` on Linux without having a native Linux desktop release from OpenAI.

## What Was In The DMG

The DMG contains a standard macOS Electron app bundle:

- `Codex.app`
- `app.asar`
- macOS native binaries and add-ons such as:
  - `better_sqlite3.node`
  - `node-pty`
  - `codex`
  - `rg`

The first hard blocker was that these binaries are macOS Mach-O files, not Linux ELF files.

## Key Findings

1. The UI and most of the application logic are portable Electron assets inside `app.asar`.
2. The desktop app does not run directly on Linux because bundled native modules are macOS-only.
3. A Linux Electron runtime can load the app if the app is launched in a packaged-like mode.
4. After replacing the first failing native module, the next required dependency is a Linux Codex CLI binary for the app-server transport.

## Linux Run Strategy

The working approach is:

1. Extract `app.asar` from `assets/Codex.dmg`.
2. Launch the extracted app with a pinned Linux Electron runtime.
3. Force Electron to behave as if the app is packaged.
4. Rebuild `better-sqlite3` for Linux against the Electron ABI used by the pinned runtime.
5. Provide Linux `codex` and `rg` binaries to the runtime.
6. Start the app through the wrapper.

## Why The Wrapper Exists

The wrapper in `runner/` does three things:

- forces `app.isPackaged` to return `true`
- sets application name and version
- loads the extracted desktop bootstrap file from the runtime cache

Without this wrapper, the extracted app falls back to development startup behavior and tries to load a dev server URL instead of the packaged app protocol.

## Why `better-sqlite3` Must Be Rebuilt

The bundled `better_sqlite3.node` is compiled for macOS and crashes on Linux with an invalid binary format.

The Linux launcher therefore rebuilds `better-sqlite3` for the exact Electron version pinned in `linux-tools/package-lock.json`, then copies the resulting `.node` file into the extracted app.

## Why A Linux Codex CLI Is Needed

The desktop app expects to spawn a Codex CLI app-server process.

The Linux launcher uses the pinned `@openai/codex` package from `linux-tools/` and exposes its `codex` executable to the Electron runtime. It also provides a Linux `rg` binary from the same toolchain.

## Reproducible Pieces In This Repo

- `run-codex-linux.sh`: end-to-end Linux bootstrap and launch
- `linux-tools/package.json`: pinned dependencies
- `linux-tools/package-lock.json`: locked versions for reproducibility
- `runner/main.js`: packaged-mode Electron wrapper

## Non-Committed Artifacts

These are intentionally ignored:

- `assets/Codex.dmg`
- `.codex-linux-runtime/`
- `linux-tools/node_modules/`
- `ai_docs/`

The repo should contain the script and pinned toolchain metadata, but not the generated runtime cache or local debugging notes.
