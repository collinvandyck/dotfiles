setopt sh_word_split
setopt noauto_cd

# setup easy access to cd paths
cdpath=($HOME/ngrok $HOME/code $HOME)

ulimit -n 2400
ulimit -n 10000 2>/dev/null

# disable control-alt-fX keys
setxkbmap -option srvrkeys:none 2>/dev/null
