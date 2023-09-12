# starting options

export FZF_DEFAULT_COMMAND='rg --files --follow --hidden -g "!.git"'

export FZF_DEFAULT_OPTS="\
	--reverse \
	--border rounded \
	--pointer ✨ \
	--marker » \
	--bind 'ctrl-p:up'  \
	--bind 'ctrl-n:down' \
	--bind 'alt-p:preview-up' \
	--bind 'alt-n:preview-down' \
	--bind 'ctrl-d:' \
	--no-hscroll \
	"

# dracula theme.
# https://draculatheme.com/fzf
FZF_DRACULA="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
FZF_CUSTOM="--color=fg:#d0d0d0,bg:#121212,hl:#5f87af --color=fg+:#d0d0d0,bg+:#262626,hl+:#5fd7ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf"
FZF_THEME=$FZF_DRACULA
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} ${FZF_THEME}"

# other options
#
export FZF_CTRL_R_OPTS='--no-sort --exact --height 100%'
export FZF_GIT_OPTS='--height 100%'
export FZF_GIT_GA_OPTS='--no-sort'
export FZF_COMPLETION_TRIGGER='..'

_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset|"echo") fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}
