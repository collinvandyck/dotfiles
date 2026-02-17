# create a new worktree. assumes that you're in the repo
new-worktree() {
    if ! git rev-parse --git-common-dir &>/dev/null; then
        echo "not in a git repo" >&2
        return 1
    fi
    root=$(echo $(realpath "$(git rev-parse --git-common-dir)/.."))
    if ! [[ -d "$root"/worktrees ]]; then
        echo "no worktrees folder" >&2
        return 1
    fi
    name="$1"
    if [[ -d "$root"/worktrees/"$name" ]]; then
        echo "worktree $name already exists"
        return 1
    fi
    ref="$2"
    [[ -z "$ref" ]] && ref="$(git_main_branch)"
    wtpath="$root/worktrees/$name"
    git worktree add "$wtpath" -b "collin/$name" "$ref"
    cd "$wtpath"
    if [[ -d "$root"/.claude ]]; then
        ln -s "$root"/.claude .
    fi
    if [[ -f "$root"/mise.toml ]]; then
        mise trust .
        mise install
    fi
}
