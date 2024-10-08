# Alias native base custom theme init
alias inb="node ./node_modules/native-base/ejectTheme.js"

# Alias for show my device IP address
alias ip='ifconfig | grep "inet "'

# Alias for check connection
alias p='ping 8.8.8.8'

# Alias for git status
alias gis='git status'

# Alias for git checkout
alias gic='git checkout'

# Alias for git merge
alias gim='git merge --no-ff'

# Alias for git branch
alias gib='git branch'

# Alias for git branch delete
alias gibd='git branch -d'

# Alias for git pull
alias gip='git pull origin'

# Alias for git push
alias gipu='git push origin'

# Alias for git log
alias gil='git log --graph --oneline --decorate --all'

# Alias for git restore
alias gir='git restore --staged'

# Alias for git verbose
alias girv='git remote --verbose'

# Alias for remove git remote url, ex: girrm origin
alias girrm='git remote rm'

# Alias for ignore update file status on
giion(){
  git update-index --assume-unchanged $1
}

# Alias for ignore update file status off
giioff(){
  git update-index --no-assume-unchanged $1
}

# Alias for clone github, ex:
# > clone github.com/mahbubzulkarnain/setup
clone(){
  git clone $1 && cd $(basename $1 .git)
}

# Alias for terminate by port, ex:
# > pk 3000
pk(){
  lsof -P | grep '$(:$1)' | awk '{print $2}' | xargs kill -9
}

# Alias for git log since 14 days ago
gils() {
    AUTHOR=${AUTHOR:="`git config user.name`"}

    since=yesterday
    if [[ $(date +%u) == 1 ]] ; then
        since="14 days ago"
    fi

    git log --all --since "$since" --oneline --author="$AUTHOR"
}

# php

# init phpbrew bashrc
# export PHPBREW_SET_PROMPT=1
# export PHPBREW_RC_ENABLE=1
# [[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

# Alias live-server
alias boom="live-server --host=localhost"

# Alias build

# Docker image
alias doi='docker images'
alias doirm='docker image rm'
alias doils='docker image ls'

# Alias for pull docker image
alias dop='docker pull'

# Alias for pull docker image
alias dol='docker ps -l'

# Docker container
alias doc='docker container'
alias docls='docker container ls'
alias doclog='docker container logs --tail'
alias docstop='docker container rm -f $(docker ps -aq)'

alias donls='docker network ls'

# Alias for Docker compose up
alias dcrun='docker-compose up -d'

# Alias for Docker compose up force rebuild
alias dcrunf='docker-compose up -d --build'

# Alias for Docker compose down
alias dcdown='docker-compose down'

# Alias for Docker compose down all volume
alias dcdownv='docker-compose down -v'

# Alias for Docker compose stop <service_name>
alias dcstop='docker-compose stop'

# Alias for Docker compose restart <service_name>
alias dcrestart='docker-compose restart'

# Alias for Docker compose show log <service_name>
alias dclog='docker-compose logs -f'


# Alias for nodemon run "go run main.go"
alias gorun='nodemon --exec go run main.go --signal SIGTERM'

# Alias for show golang test coverage
alias gotc='go test -cover'

# Alias for run golang test
alias got='go test ./... -v'

# Alias for run golangci-lint
alias goclint="golangci-lint run --exclude=\"exported \\w+ (\\S*['.]*)([a-zA-Z'.*]*) should have comment or be unexported\" --exclude-use-default=false --enable=revive	--enable=gocyclo --enable=goconst --enable=unconvert ./..."

# Alias for run staticcheck
# https://www.phillipsj.net/posts/enabling-staticcheck-in-goland/, Enabling Staticcheck in GoLand
alias goslint="staticcheck ./..."

# Alias for mvim
# alias v='mvim'

# Alias for mkdir and cd
mkcd() { mkdir -p "$@" && cd "$@"; }

# Alias for heroku
alias h='heroku'

# Alias for rubocop
alias ru='rubocop -x && rubocop -a'

# Alias for rails
alias r='rails'

# Alias for rails development
rdev() { rails "$@" RAILS_ENV=development; }

# Alias for rails production
rprod() { rails "$@" RAILS_ENV=production; }

# Alias for rails test
rtest() { rails "$@" RAILS_ENV=test; }

# Alias for rails credential edit
alias rce='EDITOR=nano rails credentials:edit'

# Alias for flutter
alias flutter='fvm flutter'

# TERM Color
export TERM="xterm-256color"

case $TERM in
    xterm*|rxvt*)
        AUTOSUGGESTION_HIGHLIGHT_COLOR="fg=8"
        ;;
    *)
        AUTOSUGGESTION_HIGHLIGHT_COLOR="fg=3"
        ;;
esac

# Android
# export ANDROID_HOME=$HOME/Library/Android/sdk
# export PATH=$PATH:$ANDROID_HOME/emulator
# export PATH=$PATH:$ANDROID_HOME/tools
# export PATH=$PATH:$ANDROID_HOME/tools/bin
# export PATH=$PATH:$ANDROID_HOME/platform-tools

# Flutter
# export FLUTTERROOT=$HOME/Systems/flutter
# export PATH=$PATH:$FLUTTERROOT/bin

# Golang
# export GOPATH=$HOME/Systems/Golang
# export GOROOT=/usr/local/opt/go/libexec

# Java
# export PATH="/usr/local/opt/openjdk/bin:$PATH"

# Java Manager Version
# export PATH="$HOME/.jenv/bin:$PATH"
# eval "$(jenv init -)"

# Sonar
export SONAR_HOME=/usr/local/Cellar/sonar-scanner/6.1.0.4477/libexec
export SONAR=$SONAR_HOME/bin
export PATH=$SONAR:$PATH

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$GOPATH/bin:$GOROOT/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="zul"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting 1password)

source $ZSH/oh-my-zsh.sh
source $(brew --prefix nvm)/nvm.sh
source $(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export PATH="$HOME/Library/Android/sdk/cmdline-tools/latest/bin:$PATH"

alias python3="/opt/homebrew/bin/python3"
export PYTHON="/opt/homebrew/bin/python3"

export CXXFLAGS="-stdlib=libc++"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /Users/mahbubzulkarnain/.dart-cli-completion/zsh-config.zsh ]] && . /Users/mahbubzulkarnain/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

eval "$(fzf --zsh)"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}