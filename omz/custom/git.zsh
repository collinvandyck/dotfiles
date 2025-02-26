alias ci='git ci'
alias cip='git cip'

function delbranch()
{
    git branch -D $1 ; git push origin :refs/heads/$1
}

function deltag()
{
    git tag -d $1 ; git push origin :refs/tags/$1
}

function gdom() {
	git diff $(git merge-base HEAD origin/$(git_main_branch)) "$@"
}

function gcobr() {
    git checkout "$(git branch --all --sort=committerdate | fzf-tmux -p --no-sort --tac | tr -d '[:space:]' | tr -d '^\* ')"
}

function fzfbranch() {
    git branch --all --sort=committerdate | fzf --no-sort --tac | tr -d '[:space:]' | tr -d '^\* '
}

