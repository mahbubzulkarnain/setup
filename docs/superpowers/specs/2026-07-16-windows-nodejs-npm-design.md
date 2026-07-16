# Node.js/npm support on Windows-native (MSYS2), including Claude Code CLI

## Problem

`npm.sh` installs Node via `nvm-sh/nvm`, which only supports Linux/macOS — it has no MSYS2/Windows path. On this Windows-native setup (added earlier in this same effort), `npm.sh` is never called by `windows.sh`, so none of the global npm packages it manages — including `@anthropic-ai/claude-code`, just added to the shared package list — get installed on Windows.

## Goal

Make `npm.sh`'s Node/npm install and global-package list work on MSYS2, and wire it into the Windows setup chain, so Claude Code CLI (and the rest of the list) become available from the "Zsh (MSYS2)" terminal on this laptop.

## Investigation: why the obvious approach doesn't work

MSYS2's `nodejs` package only exists for the `mingw-w64-*` subsystems (`mingw64`/`ucrt64`/`clangarm64`), not the base `msys` repo — the same problem already found and fixed for `fzf` in the earlier Windows-native-setup work. The `fzf` fix (download the official binary, symlink into `/usr/bin`) does not generalize to Node: verified empirically that Node's own `npm`/`npx` wrapper scripts, and every wrapper script `npm install -g` generates for a package's bin entries (confirmed concretely with the `claude` CLI's own generated wrapper), resolve their sibling files via `dirname "$0"`. A symlink into `/usr/bin` reports `$0` as the symlink's location, not the real file's directory, breaking the lookup (reproduced: `Error: Cannot find module 'C:\msys64\usr\bin\node_modules\npm\bin\npm-prefix.js'`). This means every npm-installed CLI tool would break the same way if symlinked, not just `npm` itself — symlinking isn't a viable general solution here.

Verified fix: extract Node to a fixed real directory (`/opt/nodejs`) and put that directory directly on `$PATH` (no symlinking) — confirmed working for `npm --version`, `npx --version`, and a real `npm i -g @anthropic-ai/claude-code` followed by `claude --version`.

## Design

### `npm.sh` (edit)

Restructure so platform-specific "ensure node/npm is on PATH for this script's own execution" is separated from the shared "install the global package list" block (previously the whole thing was nested under a single `linux-gnu`-only `if`):

1. MSYS2 branch: if `/opt/nodejs/node.exe` doesn't already exist, resolve the current LTS version via `https://nodejs.org/dist/index.json` (first entry where `"lts"` isn't `false` — dynamic, not a hardcoded version, matching the `fzf` fix's approach), download `node-<version>-win-x64.zip` from `nodejs.org/dist`, extract to `/opt`, and move it to the fixed path `/opt/nodejs`. Then `export PATH="/opt/nodejs:$PATH"` unconditionally (idempotent — cheap even when already installed) so the rest of *this script's own execution* can find `npm`.
2. Linux branch: unchanged (`nvm-sh/nvm` install, as today).
3. Shared block, gated on `command -v npm` (as today): the same global package list (now including `@anthropic-ai/claude-code`), plus `nvm install --lts` only on the Linux branch (moved from being the sole content of the gate to one line inside it).

### `dotfile/zsh/.zshrc` (edit)

The file already has an empty, clearly-reserved case arm for this exact purpose:
```bash
CYGWIN*|MINGW*|MSYS*)
    # Windows (using Git Bash, WSL, or similar)
    ;;
```
Add one line inside it:
```bash
CYGWIN*|MINGW*|MSYS*)
    # Windows (using Git Bash, WSL, or similar)
    [[ -d /opt/nodejs ]] && export PATH="/opt/nodejs:$PATH"
    ;;
```
Existence-guarded, so it's a safe no-op on any machine where `npm.sh` hasn't run yet, and doesn't depend on `npm.sh` having run before or after `zsh.sh` — it only matters that `/opt/nodejs` exists by the time a new interactive zsh shell starts.

### `windows.sh` (edit)

Add a third line, chaining `npm.sh` after `git.sh`/`zsh.sh`, matching how `mac.sh`/`debian.sh` already chain `npm.sh`:
```bash
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)
```

## Out of scope

- Any other npm.sh-listed tool beyond confirming the general PATH-based mechanism works (already proven via the real `claude` CLI install) — the rest of the list (eslint, typescript, jest, etc.) isn't individually re-verified, since the fix is general (PATH-based, not per-tool).
- Versioning/pinning a specific Node LTS release — always resolves "current LTS" dynamically, matching the `fzf` precedent.
- Any change to how `nvm`/Linux npm install works — untouched.

## Verification plan

Already partially done live on this machine during design (Node downloaded to `/opt/nodejs`, `npm`/`npx`/`claude` all confirmed working via PATH, `@anthropic-ai/claude-code` genuinely installed and `claude --version` returns `2.1.211 (Claude Code)`). Implementation will re-verify against the actual edited `npm.sh` (not the ad-hoc shell commands used during design), confirm idempotency on re-run, confirm the `.zshrc` case-arm line takes effect in a fresh interactive zsh shell (not just a manually-exported `PATH` in a throwaway bash session), and confirm `windows.sh`'s new chained call to `npm.sh` completes end-to-end from the pushed `master` branch.
