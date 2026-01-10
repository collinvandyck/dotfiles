if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
	setopt sh_word_split
fi

setopt noauto_cd

# setup easy access to cd paths
cdpath=(
	$HOME/code/rust-learning/aoc-2022 
	$HOME/code/rust-learning/pragprog 
	$HOME/code/rust-learning/oreilly 
	$HOME/code/rust-learning 
	$HOME/code 
	$HOME
)

ulimit -n 2400
ulimit -n 50000 2>/dev/null

# disable control-alt-fX keys
# setxkbmap -option srvrkeys:none 2>/dev/null
