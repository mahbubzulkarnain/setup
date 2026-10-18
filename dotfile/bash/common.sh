# shellcheck shell=bash
# Shared shell config for bash on Windows (Git Bash), macOS, and Linux.
# Installed to ~/.config/bash/common.sh. OS-specific PATH and env live in os-*.sh.

have() { command -v "$1" >/dev/null 2>&1; }

# Tool init. Each line is skipped when the tool is missing, so a new machine shows no errors.
have starship && eval "$(starship init bash)"
have zoxide && eval "$(zoxide init bash)"    # z and zi
have mise && eval "$(mise activate bash)"
have fzf && eval "$(fzf --bash)"             # Ctrl+R history, Ctrl+T files, Alt+C folders

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
