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

# shellcheck runs on the curated bash/sh set (it can't parse zsh); fmt/fix
# discover any tracked .sh/.zsh or bash/zsh-shebang file, skipping the few with
# zsh-specific syntax shfmt can't parse.
# Modes: shellcheck | fmt (check formatting) | fix (apply formatting in place)
lint mode:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(git rev-parse --show-toplevel)"
    case "{{mode}}" in
    shellcheck)
        shellcheck -S warning {{shell-scripts}}
        ;;
    fmt | fix)
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
        survivors=()
        for f in "${files[@]}"; do
            shfmt "$f" &>/dev/null && survivors+=("$f") || true
        done
        if [ ${#survivors[@]} -eq 0 ]; then exit 0; fi
        if [ "{{mode}}" = fix ]; then
            shfmt -w "${survivors[@]}"
        else
            shfmt -d "${survivors[@]}"
        fi
        ;;
    *)
        echo "usage: just lint {shellcheck|fmt|fix}" >&2
        exit 2
        ;;
    esac

ci:
    just lint shellcheck
    just lint fmt
    just test
