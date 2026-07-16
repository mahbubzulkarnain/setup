# Node.js/npm support on Windows-native (MSYS2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `npm.sh` work on MSYS2 (Windows-native) and wire it into `windows.sh`, so the global npm package list — including `@anthropic-ai/claude-code` — installs and becomes usable from the "Zsh (MSYS2)" terminal.

**Architecture:** `npm.sh` gets an MSYS2 branch that downloads the current Node.js LTS Windows release to a fixed real directory (`/opt/nodejs`, no symlinking — proven necessary, see spec) and puts it on `$PATH` directly. `dotfile/zsh/.zshrc`'s existing (empty) Windows case-arm gets one line to make that persist across interactive shells. `windows.sh` chains `npm.sh`, matching `mac.sh`/`debian.sh`.

**Tech Stack:** bash (MSYS2), `pacman`, `curl`, official Node.js Windows binary distribution, `npm`.

## Global Constraints

- MSYS2 detection: `[[ -n "$MSYSTEM" ]]`, never `$OSTYPE` (established in the earlier Windows-native-setup work).
- Node version is always resolved dynamically from `https://nodejs.org/dist/index.json` (first entry where `"lts"` isn't `false`) — never hardcoded.
- Fixed install path: `/opt/nodejs` — must match exactly in both `npm.sh` and `dotfile/zsh/.zshrc`.
- Never symlink Node/npm/npm-installed-package binaries into `/usr/bin` — verified broken (their wrapper scripts resolve `dirname "$0"`, which reports the symlink's location, not the real file's directory). Always use a real `$PATH` entry pointing at `/opt/nodejs`.
- Any `pacman -S` call must be `pacman -Sy` (sync database first) — lesson learned from the earlier Windows-native-setup final review (stale MSYS2 mirror databases 404 on `-S` alone for a genuinely fresh install).
- Repo working copy: `C:\Users\CODE.ID\Projects\github.com\mahbubzulkarnain\setup`, branch `master` (work directly on master is intentional/approved for this personal repo). `commit.gpgsign` is `false` locally in this repo already — don't touch that.

---

### Task 1: Restructure `npm.sh` for MSYS2

**Files:**
- Modify: `npm.sh` (whole file)

**Interfaces:**
- Consumes: nothing new.
- Produces: after this task, `npm`/`node`/`npx` and every globally-installed package (including `claude`) are reachable via `$PATH` for the remainder of whatever script/session calls `npm.sh`, as long as `/opt/nodejs` is on `$PATH` (this task adds the `export` inside `npm.sh` itself; Task 2 makes it persist in interactive shells).

- [ ] **Step 1: Rewrite `npm.sh`**

Current (full file):
```bash
#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if ! [ -s "$NVM_DIR/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    fi
    if ! command -v npm &>/dev/null; then
        echo "Install NPM..."
        nvm install --lts

        echo "Install Global node_modules"
        npm i -g node-gyp nodemon pm2 live-server

        # AI tools
        npm i -g @anthropic-ai/claude-code
        # npm i -g serverless
        # npm i -g aws-sam-local

        #npm i -g http-server
        #npm i -g json-server
        #npm i -g localtunnel

        # Database
        # npm i -g sequelize-cli

        # Debugging
        npm i -g ndb
        npm i -g node-inspector

        # Firebase
        # npm i -g firebase-tools

        # Generator
        # npm i -g @angular/cli
        # npm i -g @vue/cli
        # npm i -g express-generator
        # npm i -g create-react-app
        # npm i -g create-react-library
        # npm i -g create-react-native-app
        # npm i -g react-native-cli
        # npm i -g exp
        # npm i -g expo-cli

        # Linting
        npm i -g eslint
        npm i -g standard
        npm i -g typescript
        npm i -g tslint
        #npm i -g babel-eslint
        #npm i -g eslint-config-standard
        #npm i -g eslint-config-standard-react
        #npm i -g eslint-config-standard-jsx
        #npm i -g eslint-plugin-react
        #npm i -g eslint-config-prettier
        #npm i -g eslint-plugin-prettier
        #npm i -g prettier

        # Test
        npm i -g mocha
        npm i -g jest

        # Utilities
        npm i -g now
        #npm i -g branch-diff
        #npm i -g tldr
        #npm i -g spoof
        #npm i -g fkill-cli
        #npm i -g castnow
        #npm i -g github-is-starred-cli
        #npm i -g vtop

        #david - Find Out When Your Dependencies are Outdated
        #npm i -g david

        # Working with npm
        npm i -g yarn
        #npm i -g npx
        #npm i -g np
        #npm i -g npm-name-cli

        echo "Check list global node_modules..."
        npm list -g --depth 0

    fi
fi
```

New (full file):
```bash
#!/usr/bin/env bash

if [[ -n "$MSYSTEM" ]]; then
    if [[ ! -x /opt/nodejs/node.exe ]]; then
        echo "Install Node.js..."
        node_version=$(curl -fsSL https://nodejs.org/dist/index.json | grep -o '"version":"[^"]*"[^}]*"lts":"[^"]*"' | head -1 | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        pacman -Sy --noconfirm unzip
        curl -fsSL -o /tmp/node.zip "https://nodejs.org/dist/${node_version}/node-${node_version}-win-x64.zip"
        unzip -q -o /tmp/node.zip -d /opt
        rm -rf /opt/nodejs
        mv "/opt/node-${node_version}-win-x64" /opt/nodejs
        rm -f /tmp/node.zip
    fi
    export PATH="/opt/nodejs:$PATH"
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    if ! [ -s "$NVM_DIR/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    fi
fi

if ! command -v npm &>/dev/null; then
    echo "Install NPM..."
    [[ "$OSTYPE" == "linux-gnu" ]] && nvm install --lts

    echo "Install Global node_modules"
    npm i -g node-gyp nodemon pm2 live-server

    # AI tools
    npm i -g @anthropic-ai/claude-code
    # npm i -g serverless
    # npm i -g aws-sam-local

    #npm i -g http-server
    #npm i -g json-server
    #npm i -g localtunnel

    # Database
    # npm i -g sequelize-cli

    # Debugging
    npm i -g ndb
    npm i -g node-inspector

    # Firebase
    # npm i -g firebase-tools

    # Generator
    # npm i -g @angular/cli
    # npm i -g @vue/cli
    # npm i -g express-generator
    # npm i -g create-react-app
    # npm i -g create-react-library
    # npm i -g create-react-native-app
    # npm i -g react-native-cli
    # npm i -g exp
    # npm i -g expo-cli

    # Linting
    npm i -g eslint
    npm i -g standard
    npm i -g typescript
    npm i -g tslint
    #npm i -g babel-eslint
    #npm i -g eslint-config-standard
    #npm i -g eslint-config-standard-react
    #npm i -g eslint-config-standard-jsx
    #npm i -g eslint-plugin-react
    #npm i -g eslint-config-prettier
    #npm i -g eslint-plugin-prettier
    #npm i -g prettier

    # Test
    npm i -g mocha
    npm i -g jest

    # Utilities
    npm i -g now
    #npm i -g branch-diff
    #npm i -g tldr
    #npm i -g spoof
    #npm i -g fkill-cli
    #npm i -g castnow
    #npm i -g github-is-starred-cli
    #npm i -g vtop

    #david - Find Out When Your Dependencies are Outdated
    #npm i -g david

    # Working with npm
    npm i -g yarn
    #npm i -g npx
    #npm i -g np
    #npm i -g npm-name-cli

    echo "Check list global node_modules..."
    npm list -g --depth 0
fi
```

- [ ] **Step 2: Note the target machine's real starting state before testing**

This machine already has `/opt/nodejs` populated (Node LTS extracted, `@anthropic-ai/claude-code` already globally installed) from hands-on verification done during the design phase — this is real, intentional state, not test pollution. Confirm it's there: `& "C:\msys64\usr\bin\bash.exe" -lc 'test -x /opt/nodejs/node.exe && echo "node present"; test -d /opt/nodejs/node_modules/@anthropic-ai && echo "claude-code present"'`
Expected: both lines print.

- [ ] **Step 3: Run the rewritten script locally inside MSYS2 bash**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/npm.sh"'`
Expected: since `/opt/nodejs/node.exe` already exists, the download block is skipped (no `Install Node.js...` line) — only the unconditional `export PATH=...` runs. Then, since `command -v npm` now succeeds, the shared install block DOES run (this is the script's first real end-to-end pass with the actual file, even though `/opt/nodejs` itself was pre-populated by hand) — expect `Install NPM...`, `Install Global node_modules`, a sequence of `npm i -g ...` lines (each fast — packages already present just report up-to-date), ending with `Check list global node_modules...` and an `npm list -g --depth 0` dump that includes `@anthropic-ai/claude-code`.

- [ ] **Step 4: Confirm `claude` and the rest of the list are reachable**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'export PATH="/opt/nodejs:$PATH"; command -v claude; claude --version; command -v eslint; command -v jest; command -v yarn'`
Expected: `claude` resolves to `/opt/nodejs/claude`, `claude --version` prints a real version string (e.g. `2.1.211 (Claude Code)`), and `eslint`/`jest`/`yarn` all resolve under `/opt/nodejs`.

- [ ] **Step 5: Syntax-check**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash -n "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/npm.sh" && echo "syntax ok"'`

- [ ] **Step 6: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add npm.sh
git commit -m "Add MSYS2 support to npm.sh: install Node.js LTS to /opt/nodejs, no symlinking"
```

---

### Task 2: Persist `/opt/nodejs` on `$PATH` for interactive zsh shells

**Files:**
- Modify: `dotfile/zsh/.zshrc:370-372`

**Interfaces:**
- Consumes: `/opt/nodejs` (Task 1's fixed install path).
- Produces: `node`/`npm`/`claude`/etc. reachable from a fresh interactive "Zsh (MSYS2)" terminal, not just from `npm.sh`'s own script execution.

- [ ] **Step 1: Edit the existing empty Windows case arm**

Current (`dotfile/zsh/.zshrc:370-372`):
```bash
    CYGWIN*|MINGW*|MSYS*)
        # Windows (using Git Bash, WSL, or similar)
        ;;
```

New:
```bash
    CYGWIN*|MINGW*|MSYS*)
        # Windows (using Git Bash, WSL, or similar)
        [[ -d /opt/nodejs ]] && export PATH="/opt/nodejs:$PATH"
        ;;
```

- [ ] **Step 2: Pull the edited dotfile onto this machine and confirm it takes effect in a real interactive shell**

The live `~/.zshrc` on this machine was curled from the repo before this edit existed, so it won't have the new line yet. Re-fetch it from the local edited file to test (not from the remote — the edit isn't pushed yet):
`& "C:\msys64\usr\bin\bash.exe" -lc 'cp "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/dotfile/zsh/.zshrc" ~/.zshrc'`

- [ ] **Step 3: Confirm a genuinely fresh interactive zsh shell (not a manual `export`) resolves `claude`**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'zsh -i -c "command -v claude; claude --version"' 2>&1`
Expected: `command -v claude` resolves to `/opt/nodejs/claude` and `claude --version` prints its version — with NO manual `PATH` export in this command (proving the `.zshrc` line itself is what makes it work, not an inherited environment variable from the test harness).

- [ ] **Step 4: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add dotfile/zsh/.zshrc
git commit -m "Add /opt/nodejs to PATH in the Windows case arm of .zshrc"
```

---

### Task 3: Chain `npm.sh` into `windows.sh`, push, and verify end-to-end

**Files:**
- Modify: `windows.sh`

**Interfaces:**
- Consumes: `npm.sh` (Task 1), `dotfile/zsh/.zshrc` (Task 2), both by remote curl once pushed.
- Produces: nothing consumed elsewhere — this is the final integration point.

- [ ] **Step 1: Add the `npm.sh` call**

Current (full file):
```bash
#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
```

New (full file):
```bash
#!/usr/bin/env bash

bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/git.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/zsh.sh)
bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/npm.sh)
```

- [ ] **Step 2: Syntax-check**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc 'bash -n "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup/windows.sh" && echo "syntax ok"'`

- [ ] **Step 3: Commit**

```bash
cd "/c/Users/CODE.ID/Projects/github.com/mahbubzulkarnain/setup"
git add windows.sh
git commit -m "Chain npm.sh into windows.sh, matching mac.sh/debian.sh"
```

- [ ] **Step 4: Push — confirm with the user first**

This pushes to the user's real `origin/master` on GitHub. Confirm before running:
```bash
git push origin master
```

- [ ] **Step 5: Run the full chain end-to-end from the live pushed URL**

Run: `& "C:\msys64\usr\bin\bash.exe" -lc "bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)"`
Expected: `git.sh`/`zsh.sh` both idempotently skip (already fully set up from the earlier Windows-native-setup work), then `npm.sh` runs — since `/opt/nodejs` already exists, its download block is skipped, but the shared package-install block still runs (same as Task 1 Step 3) since this is the first time the full chain, including `npm.sh`, has executed together end-to-end via the live URL.

- [ ] **Step 6: Re-run to confirm the whole chain is idempotent**

Run the same command again: `& "C:\msys64\usr\bin\bash.exe" -lc "bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)"`
Expected: this time `command -v npm` is available from the very start of this fresh bash process only if a prior export persisted — it won't, since each `bash <(curl...)` invocation is a new non-interactive process. Expect the same behavior as Step 5 (package list re-verifies quickly, all "up to date") — note in the report if this differs, since this reflects a real, inherent characteristic of how `npm.sh` is invoked (documented as a known, accepted behavior in the design spec, not a defect to fix in this task).

- [ ] **Step 7: Final confirmation in the real terminal profile**

Open a real `Zsh (MSYS2)` interactive session and confirm `claude` works without any manual export, exactly as tested in Task 2 Step 3, but now via the fully pushed and chained flow: `& "C:\msys64\usr\bin\bash.exe" -lc 'zsh -i -c "claude --version"' 2>&1`
