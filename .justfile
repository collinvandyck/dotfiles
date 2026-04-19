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
    bats goland/apply-vmoptions.bats
    bats bin/paragraphs.bats
    python3 bin/pipefmt_test.py

lint-shellcheck:
    shellcheck -S warning {{shell-scripts}}

lint-shfmt:
    shfmt -d {{shell-scripts}}

shfmt:
    shfmt -w {{shell-scripts}}

ci:
    just lint-shellcheck
    just lint-shfmt
    just test
