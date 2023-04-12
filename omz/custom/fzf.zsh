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
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} ${FZF_DRACULA}"

# other options
#
export FZF_CTRL_R_OPTS='--no-sort --exact --height 100%'
export FZF_GIT_OPTS='--height 100%'
export FZF_GIT_GA_OPTS='--no-sort'
export FZF_COMPLETION_TRIGGER='..'
