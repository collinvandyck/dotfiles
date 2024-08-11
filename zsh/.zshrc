# disable scroll lock so that i can use Ctrl-S in neovim
stty -ixon

export TERM=xterm-256color
export ZSH_CUSTOM=~/.dotfiles/omz/custom
export ZSH="$HOME/.oh-my-zsh"

plugins=(
    git
    macos
    rust
    fzf-tab
)

# sources the file if it exists
source-if() {
	local p="$1"
	[ -f "${p}" ] && source "${p}"
}

# tests if the command exists
cmd_exists() {
	local p="$1"
	command -v "${p}" &>/dev/null
}

# setting FPATH must happen before sorucing oh-my-zsh.sh do to how OMZ works.
# https://docs.brew.sh/Shell-Completion
FPATH="$(/opt/homebrew/bin/brew --prefix)/share/zsh/site-functions:${FPATH}"
source $ZSH/oh-my-zsh.sh

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.

function zshaddhistory() {
	# defang naughty commands; the entire history entry is in $1
	if [[ $1 =~ "commentedoutcommandshere" ]]; then
		1="# $1"
	fi
	if [[ $1 =~ "^builtin cd -- " ]]; then
		1=$(echo $1 | sed 's/builtin cd --/cd/')
	fi
	# write to usual history location
	print -sr -- ${1%%$'\n'}
	# do not save the history line. if you have a chain of zshaddhistory
	# hook functions, this may be more complicated to manage, depending
	# on what those other hooks do (man zshall | less -p zshaddhistory)
	return 1
}

# only init nvm if an env var is set
if [[ -n "$USE_NVM" ]]; then
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

source-if "/opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh"
source-if ~/.fzf.zsh
source-if ~/.cde/.venv/lib/python3.11/site-packages/cde_cli/cde_cli_sh_rc.sh
source-if ~/.config/broot/launcher/bash/br

cmd_exists zoxide   && eval "$(zoxide init zsh)"
cmd_exists atuin    && eval "$(atuin init zsh --disable-up-arrow)"
cmd_exists direnv   && eval "$(direnv hook zsh)"
cmd_exists starship && eval "$(starship init zsh)"
cmd_exists broot    && eval "$(broot --print-shell-function zsh)"
cmd_exists op       && eval "$(op completion zsh)"
cmd_exists pyenv    && {
	[ "$(hostname)" = "ripm2.local" ] && eval "$(pyenv init -)"
}
if cmd_exists brew; then
    source-if "$(brew --prefix)/opt/chruby/share/chruby/chruby.sh"
    source-if "$(brew --prefix)/opt/chruby/share/chruby/auto.sh"
fi
cmd_exists chruby   && chruby ruby-3.1.3

source ~/.dotfiles/zsh/widgets.zsh
