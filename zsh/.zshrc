#zmodload zsh/zprof

# disable scroll lock so that i can use Ctrl-S in neovim
stty -ixon

export TERM=xterm-256color
export ZSH_CUSTOM=~/.dotfiles/omz/custom
export ZSH="$HOME/.oh-my-zsh"

plugins=(
    git
    macos
    #rust
)

# setting FPATH must happen before sorucing oh-my-zsh.sh do to how OMZ works.
# https://docs.brew.sh/Shell-Completion
FPATH="/opt/homebrew/share/zsh/site-functions:${FPATH}"
#zmodload zsh/zprof

# disables the update check which can cause shell startup lag.
export UPDATE_ZSH_DAYS=30

source $ZSH/oh-my-zsh.sh
#zprof | hd

HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000
setopt BANG_HIST              # Treat the '!' character specially during expansion.
setopt HIST_BEEP              # Beep when accessing nonexistent history.
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space.
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording entry.
setopt HIST_SAVE_NO_DUPS      # Don't write duplicate entries in the history file.
setopt HIST_VERIFY            # Don't execute immediately upon history expansion.
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY          # Share history between all sessions.

function zshaddhistory() {
    local line=${1%%$'\n'}
    if [[ "$line" = "builtin cd -- "* ]]; then
        print -s "cd ${line#"builtin cd -- "}"
        return 1
    fi
    return 0
}

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

# a helper to use one of the direnv modules
use() {
    local module=$1
    shift
    source ~/.dotfiles/direnv/lib/$module.sh
    use_$module
}

init-fzf() {
    source-if ~/.fzf.zsh
}
init-broot() {
    source-if ~/.config/broot/launcher/bash/br
}
init-opam() {
    # This was moved to a source-if invocation.
    # BEGIN opam configuration
    source-if ~/.opam/opam-init/init.zsh
    # END opam configuration
}
init-wasmer() {
    if [ -f ~/.wasmer/wasmer.sh ]; then
        export WASMER_DIR="${HOME}/.wasmer"
        [ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"
    fi
}
init-zoxide() {
    cmd_exists zoxide && eval "$(zoxide init zsh --cmd z)"
}
init-just() {
    cmd_exists just && eval "$(just --completions zsh)"
}
init-atuin() {
    cmd_exists atuin && eval "$(atuin init zsh --disable-up-arrow)"
}
init-direnv() {
    cmd_exists direnv && eval "$(direnv hook zsh)"
}
init-starship() {
    cmd_exists starship && eval "$(starship init zsh)"
}
init-broot() {
    cmd_exists broot && eval "$(broot --print-shell-function zsh)"
}
init-bun() {
    source-if "/Users/collin/.bun/_bun"
}
init-completions() {
    source-if "/opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh"
    source-if "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
}

#PROFILE_INIT_FNS=1
run-init-fn() {
    if [[ ! -z "$PROFILE_INIT_FNS" ]]; then
        # this branch does not run as PROFILE_INIT_FNS is not set.
        local start=$(($EPOCHREALTIME * 1000))
        $1
        local end=$(($EPOCHREALTIME * 1000))
        local duration=$((end - start))
        [[ duration -gt 50 ]] && echo >&2 "$1 took ${duration}ms"
    else
        $1
    fi
}

run-init-fn init-fzf
run-init-fn init-zoxide
run-init-fn init-just
run-init-fn init-atuin
run-init-fn init-direnv
run-init-fn init-starship
run-init-fn init-completions
run-init-fn init-bun

#run-init-fn init-broot
#run-init-fn init-opam
#run-init-fn init-broot
#run-init-fn init-wasmer

source ~/.dotfiles/zsh/widgets.zsh

# zprof | head -100

