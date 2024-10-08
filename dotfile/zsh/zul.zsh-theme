# Machine name.
function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || echo $HOST
}

# Current time info
local current_time='%{$fg[white]%}at %{$terminfo[bold]%}%D{%f/%m/%Y} %D{%H:%M:%S %Z}%{$reset_color%}'

# Directory info.
local current_dir='%{$fg[white]%}in %{$reset_color%}%{$terminfo[bold]$fg[yellow]%}${PWD/#$HOME/~}%{$reset_color%}'

current_os(){
  echo -n '%{$terminfo[bold]%}%{$reset_color%}'
}

# VCS
YS_VCS_PROMPT_PREFIX1="%{$fg[white]%}on%{$reset_color%} "
YS_VCS_PROMPT_PREFIX2=":%{$fg[cyan]%}"
YS_VCS_PROMPT_SUFFIX="%{$reset_color%}"
YS_VCS_PROMPT_DIRTY=" %{$fg[red]%}✗ "
YS_VCS_PROMPT_CLEAN=" %{$fg[green]%}✔︎ "

# Git info.
local git_info='$(git_prompt_info)'
local git_last_commit='$(git log --pretty=format:"%h%{$terminfo[bold]$fg[green]%} \"%s\"%{$reset_color%}" -1 2> /dev/null) '
ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}git${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"
ZSH_THEME_GIT_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

# HG info
local hg_info='$(ys_hg_prompt_info)'
ys_hg_prompt_info() {
	# make sure this is a hg dir
	if [ -d '.hg' ]; then
		echo -n "${YS_VCS_PROMPT_PREFIX1}hg${YS_VCS_PROMPT_PREFIX2}"
		echo -n $(hg branch 2>/dev/null)
		if [ -n "$(hg status 2>/dev/null)" ]; then
			echo -n "$YS_VCS_PROMPT_DIRTY"
		else
			echo -n "$YS_VCS_PROMPT_CLEAN"
		fi
		echo -n "$YS_VCS_PROMPT_SUFFIX"
	fi
}

PROMPT="
%{$fg[cyan]%}%n %{$fg[white]%}${current_dir}%{$reset_color%}${hg_info} ${git_info}${git_last_commit}${git_prompt_status}
%{$terminfo[bold]$fg[white]%}› %{$reset_color%}"