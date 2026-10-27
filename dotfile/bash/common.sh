# shellcheck shell=bash
# Shared shell config for bash on Windows (Git Bash), macOS, and Linux.
# Installed to ~/.config/bash/common.sh. OS-specific PATH and env live in os-*.sh.

have() { command -v "$1" >/dev/null 2>&1; }

# Tool init output is cached in ~/.cache/shell-init and rebuilt only when the tool's binary is newer
# (an upgrade). Running `fzf --bash` and friends on every start took about 2 s on Windows.
__init_cached() {
    local name=$1 bin cache dir="$HOME/.cache/shell-init"
    shift
    bin=$(command -v "$1") || return 0
    cache="$dir/$name.sh"
    if [ ! -s "$cache" ] || [ "$bin" -nt "$cache" ]; then
        mkdir -p "$dir"
        if "$@" > "$cache.tmp" 2>/dev/null; then mv -f "$cache.tmp" "$cache"; fi
    fi
    [ -s "$cache" ] && . "$cache"
}

# Tool init. Each line is skipped when the tool is missing, so a new machine shows no errors.
have starship && __init_cached starship starship init bash --print-full-init
have zoxide && __init_cached zoxide zoxide init bash    # z and zi
# zoxide runs `zoxide add` before every prompt, about 100 ms on Windows. Only run it when the folder changes.
__zoxide_last=""
__zoxide_hook_on_cd() {
    [ "$PWD" = "$__zoxide_last" ] && return 0
    __zoxide_last=$PWD
    __zoxide_hook
}
PROMPT_COMMAND="${PROMPT_COMMAND//__zoxide_hook/__zoxide_hook_on_cd}"
# zoxide 0.10's init passes "\builtin pwd -L" to cygpath as one quoted argument, so every folder is stored as
# "C:\builtin pwd -L" and `z` never finds anything on Git Bash. Use the real folder instead.
__zoxide_pwd() { cygpath -w "$(builtin pwd -L)"; }
__zoxide_oldpwd=""
# `z` to the folder you are already in makes zoxide exit 1 ("already in the only match"), and ble.sh prints
# [ble: exit 1] for it. Return 0 in that case. Real misses ("no match found") still come from zoxide.
z() {
    local target
    if [ "$#" -gt 0 ] && target=$(zoxide query -- "$@" 2>/dev/null) && [ "$target" = "$(__zoxide_pwd)" ]; then
        return 0
    fi
    __zoxide_z "$@"
}
# --shims: no hook on every prompt (that hook made each command wait). Tools still run through mise's shims.
have mise && __init_cached mise mise activate bash --shims
have fzf && __init_cached fzf fzf --bash     # Ctrl+R history, Ctrl+T files, Alt+C folders


# History. Each command is written to ~/.bash_history as soon as it runs (history -a),
# so a window closed without a clean exit keeps it. histappend stops terminals from overwriting each other.
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth                       # skip duplicates and commands that start with a space
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Prompt watchdog: a prompt that takes SLOW_PROMPT_MS (default 3000) or more is appended to
# ~/.cache/slow-prompts.log with the time, its duration, and the command that just ran. It catches rare
# stalls with evidence. Builtins only on the fast path, so it adds no process per prompt.
SLOW_PROMPT_MS=${SLOW_PROMPT_MS:-3000}
__prompt_t0=0
__prompt_begin() { __prompt_t0=${EPOCHREALTIME/./}; }
__prompt_end() {
    local ms=$(( (${EPOCHREALTIME/./} - __prompt_t0) / 1000 ))
    if [ "$ms" -ge "$SLOW_PROMPT_MS" ]; then
        mkdir -p "$HOME/.cache"
        printf '%s %6d ms  %s\n' "$(date '+%F %T')" "$ms" "$(history 1 | sed 's/^ *[0-9]* *//')" >> "$HOME/.cache/slow-prompts.log"
    fi
}
PROMPT_COMMAND="__prompt_begin; ${PROMPT_COMMAND}; __prompt_end"

# Git (same aliases as the old Nushell config)
alias gis='git status'
alias gic='git checkout'
alias gim='git merge --no-ff'
alias gib='git branch'
alias gibd='git branch -d'
alias gip='git pull origin'
alias gipu='git push origin'
alias gil='git log --graph --oneline --decorate --all'
alias gir='git restore --staged'
alias girv='git remote --verbose'
alias girrm='git remote rm'

# Ignore local changes to a tracked file, and undo it
giion() { git update-index --assume-unchanged "$1"; }
giioff() { git update-index --no-assume-unchanged "$1"; }

# Clone a repo and cd into it, e.g. clone https://github.com/mahbubzulkarnain/setup
clone() { git clone "$1" && cd "$(basename "$1" .git)" || return; }

# Commits since yesterday (14 days on Mondays) by the current git user
gils() {
    local since="yesterday"
    [ "$(date +%A)" = "Monday" ] && since="14 days ago"
    local author="${AUTHOR:-$(git config user.name)}"
    git log --all --since="$since" --oneline "--author=$author"
}

# Kill whatever listens on a port (needs lsof), e.g. pk 3000
pk() {
    lsof -ti ":$1" | while read -r pid; do kill -9 "$pid"; done
}

# IP addresses of this machine
ip() {
    case "$(uname -s)" in
        Linux) command ip -brief address ;;
        Darwin) ifconfig | grep 'inet ' ;;
        *) ipconfig ;;
    esac
}

# Ping Google DNS
alias p='ping 8.8.8.8'

# Claude Code without permission prompts
claude() { command claude --dangerously-skip-permissions "$@"; }

# Dev server with live reload
alias boom='live-server --host=localhost'

# Mkdir and cd
mkcd() { mkdir -p "$1" && cd "$1" || return; }

# Docker
alias doi='docker images'
alias doirm='docker image rm'
alias doils='docker image ls'
alias dop='docker pull'
alias dol='docker ps -l'
alias doc='docker container'
alias docls='docker container ls'
alias doclog='docker container logs --tail'
alias donls='docker network ls'
alias dcrun='docker-compose up -d'
alias dcrunf='docker-compose up -d --build'
alias dcdown='docker-compose down'
alias dcdownv='docker-compose down -v'
alias dcstop='docker-compose stop'
alias dcrestart='docker-compose restart'
alias dclog='docker-compose logs -f'

# Stop and remove every container
docstop() {
    local ids
    ids="$(docker ps -aq)"
    # Word splitting on $ids is intended: one container ID per word
    # shellcheck disable=SC2086
    [ -n "$ids" ] && docker container rm -f $ids
}

# Go
alias gorun='nodemon --exec "go run main.go" --signal SIGTERM'
alias gotc='go test ./... -cover'
alias got='go test ./... -v'
alias goclint='golangci-lint run --fix --enable=revive --enable=gocyclo --enable=goconst --enable=unconvert ./...'
alias goslint='staticcheck ./...'

# Flutter via FVM
alias flutter='fvm flutter'
alias dart='fvm dart'
alias pub='fvm pub'

# Ruby on Rails and RuboCop
alias r='rails'
alias h='heroku'
rdev() { RAILS_ENV=development rails "$@"; }
rprod() { RAILS_ENV=production rails "$@"; }
rtest() { RAILS_ENV=test rails "$@"; }
rce() { EDITOR=nano rails credentials:edit; }
ru() {
    rubocop -x
    rubocop -a
}

# Eject the native-base theme
inb() { node ./node_modules/native-base/ejectTheme.js; }
