# disable scroll lock so that i can use Ctrl-S in neovim
stty -ixon

HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000

export TERM=xterm-256color
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

for f in ~/.dotfiles/zsh/*.zsh; do source "$f"; done

# Initialize completion system (required for compdef used by many tools)
autoload -Uz compinit && compinit

source-if() { [[ -f "$1" ]] && source "$1"; }
cmd_exists() { command -v "$1" &>/dev/null; }

init-fzf() {
    source-if ~/.fzf.zsh
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
init-mise() {
    command -v mise &>/dev/null && eval "$(mise activate zsh)"
}
init-completions() {
    source-if "/opt/homebrew/opt/git-extras/share/git-extras/git-extras-completion.zsh"
    source-if "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
}
init-cloud-tools() {
    source-if ~/.cloud-tools/ct_setup_shell.sh
}

init-completions
init-cloud-tools
init-fzf
init-just
init-mise
init-starship
init-zoxide
init-atuin
init-direnv

