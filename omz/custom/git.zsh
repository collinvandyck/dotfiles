alias ci='git ci'
alias cip='git cip'

function bookmark() {
	name=$(echo "$@" | tr ' ' '-')
	if [[ "$name" == "" ]]; then
		name=bookmark
	fi
    name="collin/${name}"
    git branch "${name}" 2>/dev/null
    git branch --force "${name}" HEAD
    git co "${name}"
}

# TODO: how to enable git completion for this?
function delbranch()
{
    git branch -D $1 ; git push origin :refs/heads/$1
}

function deltag()
{
    git tag -d $1 ; git push origin :refs/tags/$1
}

function sha() {
    echo -n $(git rev-parse --short HEAD)
}

function gdom() {
	git diff $(git merge-base HEAD origin/$(git_main_branch)) 
}

function gcob() {
    git checkout "$(git branch --all --sort=committerdate | grep -v remotes | fzf --no-sort --tac | tr -d '[:space:]' | tr -d '^\* ')"
}

function gcobr() {
    git checkout "$(git branch --all --sort=committerdate | fzf --no-sort --tac | tr -d '[:space:]' | tr -d '^\* ')"
}

function fzfbranch() {
    git branch --all --sort=committerdate | fzf --no-sort --tac | tr -d '[:space:]' | tr -d '^\* '
}

