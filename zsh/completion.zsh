# ZSH completion system configuration
# Replaces oh-my-zsh completion initialization

# Load and initialize the completion system
autoload -Uz compinit

# Only regenerate .zcompdump once a day for faster startup
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Completion options
setopt ALWAYS_TO_END          # Move cursor to end of word after completion
setopt AUTO_MENU              # Show completion menu on successive tab press
setopt COMPLETE_IN_WORD       # Complete from both ends of a word
setopt LIST_PACKED            # Make completion lists more compact
unsetopt MENU_COMPLETE        # Do not autoselect the first completion entry

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Case-insensitive (all), partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $HOME/.zsh/cache/