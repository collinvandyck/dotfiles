# Dotfiles management
# Run `just` to see available recipes

set shell := ["zsh", "-cu"]

default:
    @just --list --unsorted

# ─────────────────────────────────────────────────────────────
# Installation
# ─────────────────────────────────────────────────────────────

# Run full installation (symlinks + OS-specific setup)
install:
    ./install-all

# Create/refresh symlinks only
symlinks:
    ./install-paths

# ─────────────────────────────────────────────────────────────
# Discovery
# ─────────────────────────────────────────────────────────────

# Show pinned tool versions
versions:
    @cat .versions

# Get a specific version (e.g., just version go)
version tool:
    @./bin/dotfiles-version {{tool}}

# List custom bin scripts
bins:
    @ls -1 bin/ | head -30
    @echo "... ($(ls -1 bin/ | wc -l | tr -d ' ') total)"

# List zsh functions
functions:
    @ls -1 zsh/functions/

# Show what gets symlinked
symlinks-list:
    @grep -E "^symlink " install-paths | sed 's/symlink //'
