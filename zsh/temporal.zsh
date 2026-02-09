which-release() {
    local out; out=$(
        cd ~/code/saas-temporal 2>/dev/null && \
            git tag --contains "$1" --sort=creatordate \
            | rg '^v' \
            | head -1 \
            2>/dev/null
    )
    [[ -n "$out" ]] && echo "$out"
}
