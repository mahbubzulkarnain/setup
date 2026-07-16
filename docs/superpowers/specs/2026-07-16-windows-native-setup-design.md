# Windows-native setup support (no WSL)

## Problem

This repo's `install.sh` only routes to a real target on Linux (`linux-gnu`, further split into WSL vs. Debian) and macOS (`darwin`). Windows native (Cygwin/MSYS2/win32) was stubbed with commented-out, never-implemented branches. There is no way to run this repo's setup on a Windows laptop without WSL.

## Goal

Support running the existing minimal setup — git config, zsh + oh-my-zsh + theme + dotfiles — on Windows native, using MSYS2 as the POSIX layer (chosen over Cygwin: lighter, `pacman`-based, actively maintained). Full parity with `mac.sh`/`debian.sh` (dev tools, GUI apps, browsers, etc.) is explicitly out of scope for this iteration.

## Constraint: Windows has no bash/curl out of the box

Every existing entry point (`install.sh`, `mac.sh`, `debian.sh`, `wsl.sh`) assumes a POSIX shell with `curl` is already running. Windows doesn't provide either until MSYS2 is installed. So the Windows path needs a PowerShell bootstrap step that other platforms don't need — this is the one real asymmetry in the design.

## Architecture

```
PowerShell (fresh Windows, no bash yet)
  └─ windows.ps1
       ├─ install MSYS2 via winget (idempotent: skip if C:\msys64\usr\bin\bash.exe exists)
       ├─ add/enable a "Zsh (MSYS2)" Windows Terminal profile and set it as defaultProfile
       └─ hand off: C:\msys64\usr\bin\bash.exe -lc "bash <(curl -s .../windows.sh)"
                                                              │
                                                              ▼
                                                    windows.sh (runs inside MSYS2 bash)
                                                      ├─ git.sh   (existing, +msys branch)
                                                      └─ zsh.sh   (existing, +zsh-install fix, +msys branch)
```

`install.sh` also gets a real `MSYSTEM`-based branch (replacing the dead stub) so that, from an already-open MSYS2 bash, running `install.sh` routes to `windows.sh` directly — matching how Mac/Linux already work.

MSYS2 detection uses `[[ -n "$MSYSTEM" ]]`, not `$OSTYPE`. Verified on this machine: MSYS2's bash reports `$OSTYPE=cygwin` (the underlying runtime is cygwin-derived) and `uname -s=MSYS_NT-...` — `$OSTYPE` cannot distinguish MSYS2 from real Cygwin, but `$MSYSTEM` (set to `MSYS`/`MINGW64`/etc.) is MSYS2-specific and reliable.

## Pre-existing bug found during design (blocks Debian too, not just Windows)

`zsh.sh` calls the oh-my-zsh installer expecting it to install `zsh` itself if missing. Checked the installer source (`ohmyzsh/ohmyzsh/tools/install.sh`): if `zsh` isn't already present, it prints "Zsh is not installed. Please install zsh first." and `exit 1` immediately — it never installs zsh on any platform. This has been masked because macOS ships zsh by default, so the "not installed" path never triggered in testing on Mac. On a fresh Debian box or fresh Windows/MSYS2, `zsh.sh` as it stands today would fail immediately. Fix: add an explicit per-OS zsh install (same three-way `$OSTYPE`/`$MSYSTEM` branch pattern as `git.sh`) before invoking the oh-my-zsh installer.

## File-by-file changes

### `git.sh` (existing, edit)
Add an MSYS2 branch to the existing install-git-if-missing check:
```bash
elif [[ -n "$MSYSTEM" ]]; then
    pacman -S --noconfirm git
fi
```
No sudo (MSYS2 `pacman` doesn't need it). Rest of the file (gitignore_global, user.name config) is already platform-agnostic and untouched.

### `zsh.sh` (existing, edit)
1. Add explicit zsh install per platform before the oh-my-zsh installer call (fixes the bug above, for all platforms):
   ```bash
   if [[ "$OSTYPE" == "linux-gnu" ]]; then
       apt install -y zsh
   elif [[ "$OSTYPE" == "darwin"* ]]; then
       brew install zsh
   elif [[ -n "$MSYSTEM" ]]; then
       pacman -S --noconfirm zsh
   fi
   ```
2. Guard the Homebrew-dependent block (`fzf`, `zsh-syntax-highlighting`, `zsh-autosuggestions` via brew) so MSYS2 fetches `fzf` a different way instead — Homebrew does not run on Windows and its installer aborts on non-Linux/Darwin `uname`. No plain `fzf` pacman package exists on MSYS2 either (only `mingw-w64-*-fzf`, not on `PATH` for a plain MSYS session), so MSYS2 downloads the official Windows release binary via `curl` (latest tag resolved through the GitHub API), matching the `curl -o` pattern already used elsewhere in `zsh.sh` for the theme/`.zshrc`. The two zsh plugins are already fetched via direct `git clone` further down regardless of brew, so no change needed there.
3. Everything else (oh-my-zsh install invocation, theme curl, `.zshrc` curl, final `source ~/.zshrc`) is unchanged.

### `windows.sh` (new)
Mirrors `mac.sh`/`debian.sh` structure exactly — minimal scope, just chains the two existing scripts:
```bash
#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
```

### `windows.ps1` (new)
PowerShell bootstrap, the only non-bash entry point in the repo:
1. If `C:\msys64\usr\bin\bash.exe` doesn't exist, install MSYS2: `winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements`.
2. If the Windows Terminal `settings.json` exists (`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`), add a `Zsh (MSYS2)` profile with fixed guid `{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}` (`commandline: C:\msys64\msys2_shell.cmd -defterm -no-start -msys2 -shell zsh`, icon `C:\msys64\msys2.ico`, `startingDirectory: %USERPROFILE%`) if a profile with that guid doesn't already exist, and set `defaultProfile` to that guid. This guid matches the profile already added manually to this machine earlier in this session, so the check is a true no-op here. If the file doesn't exist (Windows Terminal not installed), print a message and skip — non-fatal.
3. Hand off to MSYS2 bash: `& "C:\msys64\usr\bin\bash.exe" -lc "bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)"`.

### `install.sh` (existing, edit)
Replace the dead commented-out `cygwin`/`msys`/`win32`/`freebsd` stub block with one real branch:
```bash
elif [[ -n "$MSYSTEM" ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)
fi
```
This only helps when bash already exists (i.e., MSYS2 already installed) — the fresh-machine path is still `windows.ps1`, documented separately in the README.

### `README.md` (existing, edit)
Add a Windows section, PowerShell equivalent of the existing bash one-liners:
```powershell
irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.ps1 | iex
```

## Explicitly out of scope
- Dev tools / GUI apps parity with `mac.sh`/`debian.sh` (Node, Go, Docker, browsers, etc.)
- Cygwin support
- Handling MSYS2 installed at a non-default path
- Handling Windows without winget available (old Windows versions)
- Adding `C:\msys64\usr\bin` to the Windows `PATH` (so `zsh`/`git` work from plain `cmd.exe`/PowerShell directly) — orthogonal nicety, not needed for the setup flow itself.

## Verification plan
Since this is a personal setup repo, verification is against this actual machine (already has MSYS2 + Windows Terminal from earlier manual steps in this session):
1. Run `windows.ps1` end-to-end — confirm it's a no-op on the already-installed MSYS2, confirm the Windows Terminal profile step is idempotent against the profile already added manually earlier this session.
2. Run `windows.sh` inside MSYS2 bash — confirm `git.sh` and the fixed `zsh.sh` complete without the "Zsh is not installed" abort, oh-my-zsh installs, theme and `.zshrc` land in `~`.
3. From MSYS2 bash, confirm `$MSYSTEM` branch in `install.sh` routes correctly by inspection (no separate mechanism to "unit test" a bash conditional here beyond reading it and confirming the variable is set, which is already verified: `MSYSTEM=MSYS`).
