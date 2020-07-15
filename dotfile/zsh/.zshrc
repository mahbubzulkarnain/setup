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

# Alias for git log
alias gil='git log --graph --oneline --decorate --all'

# Alias for git restore
alias gir='git restore --staged'

# Alias for git verbose
alias girv='git remote --verbose'

# Alias for ignore update file status on
giion(){
  git update-index --assume-unchanged $1
}

# Alias for ignore update file status off
giioff(){
  git update-index --no-assume-unchanged $1
}


# Alias for clone github
clone(){
  git clone $1 && cd $(basename $1 .git)
}

# Alias for terminate by port
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

# phpbrew
[[ -e ~/.phpbrew/zshrc ]] && source ~/.phpbrew/zshrc

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

# Alias for show golang test coverage
alias gotc='go test -cover'

# Alias for run golang test
alias got='go test ./... -v'

# Alias for run golangci-lint
alias goclint="golangci-lint run --exclude-use-default=false --enable=golint	--enable=gocyclo --enable=goconst --enable=unconvert ./..."

# Alias for mvim
alias v='mvim'

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
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Flutter
export FLUTTERROOT=$HOME/Systems/flutter
export PATH=$PATH:$FLUTTERROOT/bin

# Golang
export GOPATH=$HOME/Systems/Golang
export GOROOT=/usr/local/opt/go/libexec

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$GOPATH/bin:$GOROOT/bin:$PATH

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
plugins=(z git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

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

. ~/.oh-my-zsh/plugins/z/z.sh

export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
