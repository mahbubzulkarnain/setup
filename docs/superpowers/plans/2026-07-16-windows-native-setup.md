# Windows-native setup support (no WSL) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let this repo's setup flow (git config, zsh + oh-my-zsh + theme + dotfiles) run on a Windows laptop natively, without WSL, using MSYS2 as the POSIX layer.

**Architecture:** A new `windows.ps1` PowerShell bootstrap (the repo's only non-bash entry point, needed because Windows has no bash/curl out of the box) installs MSYS2 and a Windows Terminal zsh profile, then hands off to a new `windows.sh` which chains the existing `git.sh` and `zsh.sh` — both patched with an MSYS2 branch. `install.sh` gets a real `$MSYSTEM` branch replacing its dead stub.

**Tech Stack:** bash (MSYS2), PowerShell 7 (pwsh), `pacman` (MSYS2 package manager), `winget`, oh-my-zsh installer.

## Global Constraints

- MSYS2 only, not Cygwin (spec decision).
- Detect MSYS2 via `[[ -n "$MSYSTEM" ]]` in bash, never `$OSTYPE` — verified on the target machine that `$OSTYPE=cygwin` for MSYS2's own bash, which is indistinguishable from real Cygwin; `$MSYSTEM` (e.g. `MSYS`) is MSYS2-specific.
- Scope is git + zsh + dotfiles only. No dev-tool/GUI-app parity with `mac.sh`/`debian.sh` in this plan.
- No changes to `C:\` PATH environment variable (out of scope per spec).
- Windows Terminal profile guid is fixed: `{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}` — must match exactly so re-runs are idempotent against the profile already present on the target machine's `settings.json`.
- Every new/edited bash branch must follow the existing three-way `linux-gnu` / `darwin*` / MSYS2 pattern already used in `git.sh`, with no `sudo` on the MSYS2 branch (`pacman` doesn't need it).
- Repo working copy for this plan: `C:\Users\CODE.ID\Projects\github.com\mahbubzulkarnain\setup` (branch `master`). `commit.gpgsign` is set to `false` locally in this repo already (Bitwarden SSH agent not active on this machine) — do not change that as part of this plan.

---

### Task 1: Add MSYS2 branch to `git.sh`

**Files:**
- Modify: `git.sh:5-9`

**Interfaces:**
- Consumes: nothing new.
- Produces: `git.sh` now installs git on MSYS2 via `pacman`. `windows.sh` (Task 3) and `install.sh`'s MSYS2 branch (Task 4) both rely on this.

- [ ] **Step 1: Edit the install-git-if-missing block**

Current (`git.sh:3-10`):
```bash
if ! command -v git &>/dev/null; then
    echo "Install git..."
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        apt install -y git
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git
    fi
fi
```

New:
```bash
if ! command -v git &>/dev/null; then
    echo "Install git..."
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        apt install -y git
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git
    elif [[ -n "$MSYSTEM" ]]; then
        pacman -S --noconfirm git
    fi
fi
```

- [ ] **Step 2: Verify current state has no git inside MSYS2 bash**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'command -v git; echo "exit:$?"'`
Expected: empty output then `exit:1` (git not found — confirms this test will actually exercise the new branch, not skip it).

- [ ] **Step 3: Run the edited script locally inside MSYS2 bash**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/git.sh"'`
Expected output includes `Install git...` followed by pacman installing the `git` package, then `Setting up Git global` and `Setting up Git user.name...` (both config checks trigger since this is a fresh MSYS2 home).

- [ ] **Step 4: Confirm git is now present and configured**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'command -v git; git config --global core.excludesfile; git config --global user.name'`
Expected:
```
/usr/bin/git
/home/CODE.ID/.gitignore_global
Mahbub Zulkarnain
```

- [ ] **Step 5: Re-run to confirm idempotency**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/git.sh"'`
Expected: no `Install git...` line this time (git already present), no `Setting up Git global` / `Setting up Git user.name...` lines either (both checks already satisfied) — script produces no output.

- [ ] **Step 6: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add git.sh
git commit -m "Add MSYS2 branch to git.sh for Windows-native setup"
```

---

### Task 2: Fix `zsh.sh` (missing zsh install) and add MSYS2 branch

**Files:**
- Modify: `zsh.sh` (whole file)

**Interfaces:**
- Consumes: nothing new.
- Produces: `zsh.sh` now installs zsh itself (oh-my-zsh's installer never does, on any platform — confirmed by reading `ohmyzsh/ohmyzsh/tools/install.sh`, which `exit 1`s with "Zsh is not installed. Please install zsh first." if zsh is missing). MSYS2 branch also swaps the Homebrew-only `fzf`/plugin install for `pacman`. `windows.sh` (Task 3) relies on this being fixed to complete without aborting.

- [ ] **Step 1: Rewrite `zsh.sh`**

Current (full file):
```bash
#!/usr/bin/env bash

if ! command -v zsh &>/dev/null; then
    echo  "Install ohmyzsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if ! command -v brew &>/dev/null; then
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/brew.sh)
    fi

    brew install fzf zsh-syntax-highlighting zsh-autosuggestions
    
    cd ~ || exit

    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    curl -o ~/.oh-my-zsh/themes/zul.zsh-theme https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/zul.zsh-theme
    curl -o ~/.zshrc https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/.zshrc 
fi

source ~/.zshrc
```

New (full file):
```bash
#!/usr/bin/env bash

if ! command -v zsh &>/dev/null; then
    echo "Install zsh..."
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        apt install -y zsh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install zsh
    elif [[ -n "$MSYSTEM" ]]; then
        pacman -S --noconfirm zsh
    fi

    echo "Install ohmyzsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if [[ -n "$MSYSTEM" ]]; then
        pacman -S --noconfirm unzip
        fzf_version=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        curl -fsSL -o /tmp/fzf.zip "https://github.com/junegunn/fzf/releases/download/v${fzf_version}/fzf-${fzf_version}-windows_amd64.zip"
        unzip -o /tmp/fzf.zip -d /tmp
        install -m 755 /tmp/fzf.exe /usr/bin/fzf
        rm -f /tmp/fzf.zip /tmp/fzf.exe
    else
        if ! command -v brew &>/dev/null; then
            bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/brew.sh)
        fi

        brew install fzf zsh-syntax-highlighting zsh-autosuggestions
    fi

    cd ~ || exit

    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

    curl -o ~/.oh-my-zsh/themes/zul.zsh-theme https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/zul.zsh-theme
    curl -o ~/.zshrc https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/dotfile/zsh/.zshrc
fi

source ~/.zshrc
```

> **Revised after Task 2's first implementation pass:** the brief originally
> specified `pacman -S --noconfirm fzf` for the MSYS2 branch. The implementer
> found this fails unconditionally on a plain MSYS2 session (`MSYSTEM=MSYS`)
> — no plain `fzf` package exists in the base `msys` pacman repo, only
> `mingw-w64-*-fzf` variants whose binaries aren't on `PATH` for a plain MSYS
> session (confirmed by reading `C:\msys64\etc\profile`). Root-caused and
> fixed by fetching the official Windows release binary via `curl`
> (using the GitHub API to resolve the latest tag rather than a hardcoded
> version), matching the `curl -o` pattern already used elsewhere in this
> file for the theme and `.zshrc`. This block above reflects the corrected
> version; the fix was applied as a follow-up commit to Task 2, not a plan
> rewrite from scratch.

- [ ] **Step 2: Simulate a fresh machine by removing the manually-installed zsh package**

The target machine already has `zsh` installed manually (from earlier in this session), which would make `command -v zsh` succeed and skip the whole block under test — remove it first so the test actually exercises the fix, exactly like a real fresh-Windows user would hit it.

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'pacman -R --noconfirm zsh; command -v zsh; echo "exit:$?"'`
Expected: pacman removes the `zsh` package, then empty output followed by `exit:1`.

- [ ] **Step 3: Run the fixed script locally inside MSYS2 bash**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/zsh.sh"'`
Expected output, in order: `Install zsh...` → pacman installing `zsh` → `Install ohmyzsh...` → oh-my-zsh installer output ending in its success banner (NOT the "Zsh is not installed" abort message) → pacman installing `unzip` → curl fetching the latest fzf release zip → `fzf` installed to `/usr/bin/fzf` → two `git clone` lines for the zsh plugins → no errors from the two `curl -o` lines.

- [ ] **Step 4: Confirm the full setup landed correctly**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'command -v zsh; test -d ~/.oh-my-zsh/plugins/zsh-autosuggestions && echo "plugin-autosuggestions: ok"; test -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting && echo "plugin-syntax-highlighting: ok"; test -f ~/.oh-my-zsh/themes/zul.zsh-theme && echo "theme: ok"; test -f ~/.zshrc && echo "zshrc: ok"; command -v fzf'`
Expected:
```
/usr/bin/zsh
plugin-autosuggestions: ok
plugin-syntax-highlighting: ok
theme: ok
zshrc: ok
/usr/bin/fzf
```

- [ ] **Step 5: Re-run to confirm idempotency**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/zsh.sh"'`
Expected: no `Install zsh...`/`Install ohmyzsh...` block runs (zsh already present) — only `source ~/.zshrc` executes, no error, no other output.

- [ ] **Step 6: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add zsh.sh
git commit -m "Fix zsh.sh: install zsh explicitly (oh-my-zsh installer never does), add MSYS2 branch"
```

---

### Task 3: Create `windows.sh`

**Files:**
- Create: `windows.sh`

**Interfaces:**
- Consumes: nothing new (chains `git.sh`/`zsh.sh` by remote curl, matching how `mac.sh`/`debian.sh` already chain siblings).
- Produces: `windows.sh`, the file `windows.ps1` (Task 5) and `install.sh`'s MSYS2 branch (Task 4) both invoke.

- [ ] **Step 1: Create the file**

```bash
#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
```

- [ ] **Step 2: Syntax-check the new file**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash -n "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/windows.sh" && echo "syntax ok"'`
Expected: `syntax ok`

Full behavioral test (curling the pushed versions of `git.sh`/`zsh.sh`) happens in Task 7, after this repo is pushed — until then, `windows.sh` would only be able to pull the old, unfixed versions from `origin/master`.

- [ ] **Step 3: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add windows.sh
git commit -m "Add windows.sh: MSYS2 entry point chaining git.sh and zsh.sh"
```

---

### Task 4: Add MSYS2 branch to `install.sh`

**Files:**
- Modify: `install.sh` (whole file)

**Interfaces:**
- Consumes: `windows.sh` (Task 3) by remote curl.
- Produces: `install.sh` now routes MSYS2 bash sessions to `windows.sh`.

- [ ] **Step 1: Rewrite `install.sh`**

Current (full file):
```bash
#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/wsl.sh)
    else
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/debian.sh)
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh)
fi

echo "Link start!!!"

#elif [[ "$OSTYPE" == "cygwin" ]]; then
#        # POSIX compatibility layer and Linux environment emulation for Windows
#        echo 'mac'
#elif [[ "$OSTYPE" == "msys" ]]; then
#        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
#        echo 'mac'
#elif [[ "$OSTYPE" == "win32" ]]; then
#        # I'm not sure this can happen.
#        echo 'mac'
#elif [[ "$OSTYPE" == "freebsd"* ]]; then
#        # ...
#        echo 'mac'
#else
#        # Unknown.
#        echo 'undefined'
#fi
```

New (full file):
```bash
#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/wsl.sh)
    else
        bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/debian.sh)
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/mac.sh)
elif [[ -n "$MSYSTEM" ]]; then
    bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)
fi

echo "Link start!!!"
```

- [ ] **Step 2: Syntax-check**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash -n "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/install.sh" && echo "syntax ok"'`
Expected: `syntax ok`

- [ ] **Step 3: Confirm the MSYS2 branch condition is true on the target machine**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'echo "MSYSTEM=$MSYSTEM"'`
Expected: `MSYSTEM=MSYS` (already verified earlier in this session — re-confirming here since `install.sh`'s new branch depends on it).

Full behavioral test happens in Task 7, after push.

- [ ] **Step 4: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add install.sh
git commit -m "Route MSYS2 sessions to windows.sh in install.sh, remove dead OS stub"
```

---

### Task 5: Create `windows.ps1`

**Files:**
- Create: `windows.ps1`

**Interfaces:**
- Consumes: `windows.sh` (Task 3) by remote curl, via MSYS2 bash handoff.
- Produces: `windows.ps1`, the file `README.md` (Task 6) documents as the Windows entry point.

- [ ] **Step 1: Create the file**

```powershell
$ErrorActionPreference = "Stop"

$msys2Bash = "C:\msys64\usr\bin\bash.exe"
$zshProfileGuid = "{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}"
$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (-not (Test-Path $msys2Bash)) {
    Write-Host "Installing MSYS2..."
    winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "MSYS2 already installed, skipping."
}

if (Test-Path $terminalSettingsPath) {
    $settings = Get-Content $terminalSettingsPath -Raw | ConvertFrom-Json
    $existingProfile = $settings.profiles.list | Where-Object { $_.guid -eq $zshProfileGuid }

    if (-not $existingProfile) {
        Write-Host "Adding Zsh (MSYS2) Windows Terminal profile..."
        $zshProfile = [ordered]@{
            commandline       = "C:\msys64\msys2_shell.cmd -defterm -no-start -msys2 -shell zsh"
            guid              = $zshProfileGuid
            hidden            = $false
            icon              = "C:\msys64\msys2.ico"
            name              = "Zsh (MSYS2)"
            startingDirectory = "%USERPROFILE%"
        }
        $settings.profiles.list = @($zshProfile) + @($settings.profiles.list)
    } else {
        Write-Host "Zsh (MSYS2) Windows Terminal profile already present, skipping."
    }

    $settings.defaultProfile = $zshProfileGuid
    $settings | ConvertTo-Json -Depth 10 | Set-Content $terminalSettingsPath -Encoding utf8
} else {
    Write-Host "Windows Terminal settings.json not found, skipping terminal profile setup."
}

Write-Host "Running windows.sh inside MSYS2 bash..."
& $msys2Bash -lc "bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)"
```

- [ ] **Step 2: Back up the live Windows Terminal settings.json before testing**

Run: `Copy-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" "$env:TEMP\windows-terminal-settings.json.bak" -Force`
Expected: no output, file copied.

- [ ] **Step 3: Test the idempotent path (profile already present)**

Run the actual file as-is: `powershell -File "C:\Users\CODE.ID\Projects\github.com\mahbubzulkarnain\setup\windows.ps1"`
Since the target machine already has both MSYS2 and the guid'd profile from earlier in this session, expect:
```
MSYS2 already installed, skipping.
Zsh (MSYS2) Windows Terminal profile already present, skipping.
Running windows.sh inside MSYS2 bash...
```
followed by a harmless curl/bash error from the final handoff line — `windows.sh` isn't pushed to `origin/master` yet (that happens in Task 7), so `curl` returns a 404 body and `bash` fails to execute it. That trailing error is expected at this point in the plan; everything before it is what this step verifies.

Confirm `defaultProfile` in the settings file still equals `{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}` afterward: `(Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Raw | ConvertFrom-Json).defaultProfile`

- [ ] **Step 4: Test the fresh-add path by temporarily removing the profile, then re-running**

Remove the guid'd profile from the live settings.json (simulating a machine that has MSYS2 but not yet the Terminal profile):
```powershell
$p = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$s = Get-Content $p -Raw | ConvertFrom-Json
$s.profiles.list = @($s.profiles.list | Where-Object { $_.guid -ne "{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}" })
$s | ConvertTo-Json -Depth 10 | Set-Content $p -Encoding utf8
```
Then re-run the file: `powershell -File "C:\Users\CODE.ID\Projects\github.com\mahbubzulkarnain\setup\windows.ps1"`
Expected output (again followed by the same expected trailing curl/bash error, since `windows.sh` still isn't pushed):
```
MSYS2 already installed, skipping.
Adding Zsh (MSYS2) Windows Terminal profile...
Running windows.sh inside MSYS2 bash...
```
Confirm the profile is back: `((Get-Content $p -Raw | ConvertFrom-Json).profiles.list | Where-Object { $_.guid -eq "{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}" }).name` → expected `Zsh (MSYS2)`.

- [ ] **Step 5: Restore from backup to guarantee a byte-for-byte known-good state, then let Step 3/4's own re-add stand**

Since Step 4 already restored an equivalent profile via the script's own logic, just confirm no other part of the file was disturbed:
Run: `Compare-Object (Get-Content "$env:TEMP\windows-terminal-settings.json.bak") (Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json")`
This will show formatting diffs (JSON re-serialization reformats whitespace) — that's expected and harmless since `settings.json` isn't version-controlled. Confirm no *profile* other than formatting changed by checking profile count: `(Get-Content "$env:TEMP\windows-terminal-settings.json.bak" -Raw | ConvertFrom-Json).profiles.list.Count` should equal the current file's count.

The final MSYS2-handoff line is tested in Task 7, after push.

- [ ] **Step 6: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add windows.ps1
git commit -m "Add windows.ps1: PowerShell bootstrap for Windows-native setup"
```

---

### Task 6: Document Windows in `README.md`

**Files:**
- Modify: `README.md:37-38` (insert a new section right after the existing Mac section and before the NPM section, mirroring where `Debian`/`Mac` sit)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing consumed elsewhere — documentation only.

- [ ] **Step 1: Insert a Windows section**

Insert after the existing Mac section (`README.md`, right after the ` ```  ` closing the Mac code block, before the NPM section):
```markdown
###### Windows
```
```
irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.ps1 | iex
```
```

- [ ] **Step 2: Review the rendered diff**

Run: `cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup" && git diff README.md`
Expected: a clean, minimal diff adding exactly the 4 lines above (heading + fenced code block) in the right spot, no unrelated reformatting.

- [ ] **Step 3: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add README.md
git commit -m "Document Windows-native setup entry point in README"
```

---

### Task 7: Push and run the full end-to-end flow

**Files:** none (integration verification only).

**Interfaces:**
- Consumes: everything from Tasks 1-6, now live on `origin/master`.
- Produces: a working, idempotent Windows-native setup on the target machine — the deliverable this whole plan exists for.

- [ ] **Step 1: Confirm all prior commits are present and clean**

Run: `cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup" && git log --oneline -6 && git status`
Expected: 6 new commits from Tasks 1-6 on top of `ca9f5df`, working tree clean.

- [ ] **Step 2: Push — ask the user to confirm first**

This pushes to the user's real `origin/master` on GitHub. Confirm with the user before running:
```bash
git push origin master
```

- [ ] **Step 3: Run the full `windows.ps1` flow end-to-end (second time overall — tests idempotency of the whole chain, not just the Terminal-profile part)**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc "true"` first just to confirm bash still responds, then run the actual entry point exactly as a real user would, from the pushed raw URL:
```powershell
irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.ps1 | iex
```
Expected output, in order:
```
MSYS2 already installed, skipping.
Zsh (MSYS2) Windows Terminal profile already present, skipping.
Running windows.sh inside MSYS2 bash...
```
followed by `git.sh`'s idempotent no-output run (git already installed from Task 1), then `zsh.sh`'s idempotent no-output-except-`source`run (zsh already installed from Task 2's test).

- [ ] **Step 4: Final state check**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'command -v git; command -v zsh; command -v fzf; test -f ~/.zshrc && echo "zshrc: ok"; test -f ~/.oh-my-zsh/themes/zul.zsh-theme && echo "theme: ok"'`
Expected:
```
/usr/bin/git
/usr/bin/zsh
/usr/bin/fzf
zshrc: ok
theme: ok
```

- [ ] **Step 5: Confirm `install.sh`'s MSYS2 branch works too (the already-have-bash entry point)**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc "bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/install.sh)"`
Expected: same idempotent no-op chain as Step 3 (git.sh/zsh.sh both already satisfied), ending with `Link start!!!`.
