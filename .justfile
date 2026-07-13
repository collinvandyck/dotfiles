set shell := ["zsh", "-cu"]

default:
    @just --list --unsorted

shell-scripts := "install-all install-common install-darwin install-homebrew install-js install-k8s install-launchd install-linux install-paths install-rust install-systemd install-go bin/dotfiles-version bin/symlink bin/update goland/apply-vmoptions"

install:
    ./install-all

symlinks:
    ./install-paths

versions:
    @cat .versions

version tool:
    @./bin/dotfiles-version {{tool}}

test:
    bats **/*.bats
    python3 bin/pipefmt_test.py

lint-shellcheck:
    shellcheck -S warning {{shell-scripts}}

lint-shfmt:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    files=()
    while IFS= read -r -d '' f; do
        [ -f "$f" ] || continue
        case "$f" in
        *.sh | *.zsh) files+=("$f") ; continue ;;
        esac
        IFS= read -r shebang <"$f" 2>/dev/null || true
        case "$shebang" in
        '#!'*bash* | '#!'*zsh*) files+=("$f") ;;
        esac
    done < <(git ls-files -z)
    # drop anything shfmt can't parse (zsh-specific syntax) so they don't fail the run
    survivors=()
    for f in "${files[@]}"; do
        shfmt "$f" &>/dev/null && survivors+=("$f") || true
    done
    if [ ${#survivors[@]} -eq 0 ]; then exit 0; fi
    shfmt -d "${survivors[@]}"

shfmt:
    shfmt -w {{shell-scripts}}

ci:
    just lint-shellcheck
    just lint-shfmt
    just test
