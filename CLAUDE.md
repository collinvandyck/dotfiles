# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains dotfiles for configuring various developer tools across macOS and Linux environments. It follows a modular approach with separate directories for different tools and platforms, making it easy to maintain and extend.

## Installation Process

The main installation workflow is handled by these scripts:

- `install-all`: Main entry point that sets environment variables for tool versions
- `install-paths`: Creates symlinks from dotfiles to appropriate locations
- `install-common`: Cross-platform installations (fzf, oh-my-zsh, tmux plugin manager)
- `install-darwin`/`install-linux`: OS-specific installations
- Language-specific installations: `install-go`, `install-rust`, `install-python`, `install-js`

On macOS, Homebrew is used for package management, installed via `install-homebrew`.

## Key Commands

### Installation

```bash
# Full installation (symlinks + dependencies)
./install-all

# Only create symlinks
./install-paths

# Install specific components
./install-homebrew
./install-go
./install-rust
./install-python
./install-js
```

### Adding New Dotfiles

When adding new configuration files:
1. Add the file to the appropriate directory in the repository
2. Update `install-paths` to create the necessary symlink

## Core Features

### Shell Configuration (ZSH)

The ZSH configuration includes:
- Custom functions for Git, navigation, and development workflows
- Advanced aliases for common commands and tools
- Integration with tools like fzf, direnv, atuin, and zoxide
- Custom key bindings and widgets for improved productivity

### Development Tools

Key tools and their configurations:
- **Neovim**: Lua-based configuration with plugins
- **Git**: Custom aliases and integrations
- **tmux**: Session management with custom keybindings
- **direnv**: Environment variable management with custom modules
- **Terminal emulators**: kitty, alacritty, ghostty configurations

### Workflow Optimizations

Notable productivity enhancements:
- FZF integrations for fuzzy file finding and Git operations
- Custom tmux session management
- Directory navigation with zoxide
- Shell history management with atuin
- Terminal-based file management with tools like lsd and broot

## Platform-Specific Features

The dotfiles handle platform differences:
- **macOS**: Additional Homebrew packages, macOS-specific defaults
- **Linux**: Different symlink paths and package installations
- **Architecture-specific**: Special handling for arm64/aarch64

## Contributing to the Dotfiles

When modifying the dotfiles:
1. Test changes on your local machine before committing
2. For new tools, add installation steps to the appropriate install script
3. For configuration files, make sure to update `install-paths` if needed
4. Keep platform-specific code in the appropriate install scripts

# Commands

On my system, `bat` is aliased to `cat`. If you want to use `cat` use `command cat` instead.

# Misc

Do not try to open Markdown files using the system default application. I use neovim in a terminal and that does not work. You may notify me that I should take a look.

