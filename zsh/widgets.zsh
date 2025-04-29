# fix for zsh alt left / right not working while in tmux
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# emacs is the king of line editing
# bindkey '\e' vi-cmd-mode

#KEYTIMEOUT=1 # 100ms

prepend-sudo() {
  if [[ $BUFFER != "sudo "* ]]; then
    BUFFER="sudo $BUFFER"; CURSOR+=5
  fi
}

zle -N prepend-sudo
bindkey -M vicmd s prepend-sudo
bindkey "^[su" prepend-sudo

# expand aliases on current command line
globalias() {
	zle _expand_alias
	zle expand-word
	#zle self-insert
}
zle -N globalias
bindkey -M emacs "^ " globalias
