set shell := ["zsh", "-cu"]

default:
    @just --list --unsorted

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

