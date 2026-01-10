function grhob() {
    if [[ -n "$(git status --porcelain)" ]]; then
        echo >&2 "ERROR: Working tree is dirty."
        return 1
    fi
    git reset --hard origin/$(git branch --show-current)
}

