# an opinionated workflow on using git worktrees
worktrees() {

    usage="usage: $(basename "$0")"
    error() { echo >&2 "error: $*" }
    root() { echo "$(git rev-parse --git-common-dir)/.." }
    branch() { echo "$USER/wt-$1" }
    worktree-dir() { echo "$(root)/worktrees/$*" }

    create-worktree() {
        # TODO: link the .idea folder into the new worktree
        # ln -s $(pwd)/.idea worktrees/cet-19921-xero-metrics/.idea

        [[ $# -lt 1 ]] && error "$usage: create [name] [--force]" && return 1
        name=$1; shift
        br="-b"
        commit=@
        while [[ $# -gt 0 ]]; do
            case $1 in
                --force|-f) br="-B"
                    ;;
                *)
                    [[ "$commit" != "@" ]] && error "cannot pass more than one ref" && return 1
                    commit=$1
                    ;;
            esac
            shift
        done
        branch="$(branch "$name")"
        if [[ "$br" == "-b" ]] && git rev-parse $branch &>/dev/null; then
            error "Branch $branch already exists. Use --force to override" && return 1
        fi
        root=$(root)
        [[ ! -d "$root" ]] && error "not in a git repo!" && return 1
        full_path="$root"/worktrees/"$name"
        if [[ -d "$full_path" ]]; then
            echo "Changing into existing worktree"
        else
            git worktree add "$full_path" "$br" "$branch" "$commit"
        fi
        cd "$full_path"
    }

switch-worktree() {
    [[ $# -lt 1 ]] && error "$usage: switch [name] ..." && return 1
    cd "$(worktree-dir "$1")"
}

remove-worktree() {
    [[ $# -lt 1 ]] && error "$usage: remove [name] ..." && return 1
    root=$(root)
    git worktree remove "$@" || return $?
    cd $root
}

list-worktrees() {
    git worktree list
}

case "$1" in
    "create")
        shift
        create-worktree "$@"
        ;;
    "remove")
        shift
        remove-worktree "$@"
        ;;
    "switch")
        shift
        switch-worktree "$@"
        ;;
    "list")
        shift
        list-worktrees "$@"
        ;;

    *)
        list-worktrees
        ;;
esac
}
