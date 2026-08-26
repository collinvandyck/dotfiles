set shell := ["zsh", "-cu"]

default:
    @just --list --unsorted

shell-scripts := "install-all install-common install-darwin install-homebrew install-js install-k8s install-launchd install-linux install-paths install-rust install-systemd install-go bin/dotfiles-version bin/symlink bin/update bin/ghosttyctl goland/apply-vmoptions"

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
    just raycast-test

# Raycast only holds one extension in dev mode at a time, so this one names its
# extension instead of defaulting to all of them. A new extension has to go
# through a dev run once before Raycast knows it exists — building alone leaves
# the bundle on disk unregistered. The registration survives Ctrl-C.

# Watch one extension and hot-rebuild on save; runs until Ctrl-C.
raycast-dev ext:
    cd raycast/extensions/{{ext}} && npx ray develop

# Build one extension, or every extension when none is named.
raycast-build ext="":
    #!/usr/bin/env bash
    set -euo pipefail
    # Assigned first so an unknown extension aborts rather than looping zero times.
    exts="$(just _raycast-exts "{{ext}}")"
    cd "$(git rev-parse --show-toplevel)/raycast/extensions"
    for ext in $exts; do
        echo "== $ext"
        (cd "$ext" && npx ray build)
    done

# A suite is a no-op until its deps are installed (npm install in the
# extension's directory), which keeps `just ci` working on a fresh clone.

# Run one extension's vitest suite, or every extension's when none is named.
raycast-test ext="":
    #!/usr/bin/env bash
    set -euo pipefail
    exts="$(just _raycast-exts "{{ext}}")"
    cd "$(git rev-parse --show-toplevel)/raycast/extensions"
    for ext in $exts; do
        if [ -d "$ext/node_modules" ]; then
            echo "== $ext"
            (cd "$ext" && npx vitest run)
        else
            echo "$ext: node_modules missing, skipping vitest (run npm install to enable)"
        fi
    done

# The extension to act on, or all of them when the argument is empty. Names
# can't contain spaces, so callers can iterate the output unquoted.
[private]
_raycast-exts ext="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "{{ext}}" ]; then
        if [ ! -d "$(git rev-parse --show-toplevel)/raycast/extensions/{{ext}}" ]; then
            echo "no such extension: {{ext}}" >&2
            exit 1
        fi
        echo "{{ext}}"
        exit 0
    fi
    cd "$(git rev-parse --show-toplevel)/raycast/extensions"
    for dir in */; do echo "${dir%/}"; done

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
