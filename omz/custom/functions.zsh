# remove functions set by oh my zsh
unset -f d
unset -f git_main_branch

SCRIPT_PATH="${0:A:h}"
source ${SCRIPT_PATH}/functions/*

