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

### Justfile

This repo uses `.justfile` (hidden) for task running. Run `just` to see available recipes. When adding justfiles to other projects, use `.justfile` as the standard filename.

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

## Claude Code Configuration

Claude Code configuration lives in `ai/claude/code/` and is symlinked to `~/.claude/` via `install-paths`.

### Directory Structure

```
ai/claude/code/
├── CLAUDE.md        # Global Claude instructions (symlinked to ~/.claude/)
├── settings.json    # Permissions and settings
├── commands/        # Custom slash commands (*.md files)
├── skills/          # Skills with instructions (*/skill.md)
└── scripts/         # Helper scripts used by skills
```

### Adding New Claude Components

**Skills** (`ai/claude/code/skills/<name>/skill.md`):
- Skills provide context and instructions for specific capabilities
- The skill.md file contains usage patterns, code examples, and important notes
- Helper scripts that skills reference should go in `scripts/`

**Scripts** (`ai/claude/code/scripts/`):
- Executable helper scripts used by skills or commands
- Referenced via `~/.claude/scripts/<script>` in skill documentation
- Make scripts executable (`chmod +x`)

**Commands** (`ai/claude/code/commands/`):
- Custom slash commands as markdown files

**Settings** (`ai/claude/code/settings.json`):
- Auto-allow rules for tools (e.g., `Bash(python3:*)`)
- Permissions configuration

### Pattern: When Creating New Skills

1. Create `ai/claude/code/skills/<name>/skill.md` with instructions
2. If the skill needs helper scripts, add them to `ai/claude/code/scripts/`
3. Reference scripts as `~/.claude/scripts/<script>` in the skill docs
4. If the skill needs auto-allowed tools, add them to `settings.json`
5. Symlinks are already set up - new files will be available immediately

# Commands

On my system, `bat` is aliased to `cat`. If you want to use `cat` use `command cat` instead.

# Misc

Do not try to open Markdown files using the system default application. I use neovim in a terminal and that does not work. You may notify me that I should take a look.

