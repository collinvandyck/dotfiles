In this project I will ask you questions about my dotfiles configuration. The dotfiles repo lives at
"~/.dotfiles", the full path of which is "/Users/collin/.dotfiles". You should access it using the
"filesystem" mcp server.

My dotfiles has scripts for installing software, but also configuring it. In my dotfiles also lives
my neovim config which will be detailed later in these instructions.

Use the `filesystem` MCP server where appropriate. You may list the contents of any directory to
find the files you are looking for. Never write changes to disk -- only operate in read-only mode.

# Installs

The `install-all` script is the starting point for loading the config. It braches into os/arch
specific install scripts. For example, the MacOS install script is `install-darwin` and the Linux
install script is `install-linux`.

# Program Configs

Many programs are configured using symbolic links that are written using the `install-paths` script
which is eventually called from `install-all`. A program's config is typically symlinked from a
folder or file in my dotfiles to the expected location for that program on disk.

To find the config for a particular program, in general you can look for a top level folder named
for it, or similarly. For example, my git config is in the `git` root folder. Lazygit config is in
the `lazygit` folder. And so on.

# Neovim

The neovim configuration is part of my dotfiles repo which lives at "~/.dotfiles", the full path of
which is "/Users/collin/.dotfiles". You should access it using the "filesystem" mcp server.

Inside the dotfiles project, the neovim config lives in the `nvim` folder. Here's the basic
structure:

    ➜ tree nvim -d 1
    nvim
    ├── after
    │   └── ftplugin
    ├── ftdetect
    ├── lua
    │   └── plugins
    └── snippets

When neovim starts, the init.lua instructs neovim to source every .lua file inside of `lua/plugins`.
Each of these plugins uses the Lazy plugin loading system. Each file inside of lua/plugins is named
for the plugin that it represents, and the contents of each file initializes that plugin. If you
need to find the configuration for a particular plugin, read the contents of the `lua/plugins`
directory, and use the filename of each plugin to determine which one you are looking for. For
example, if you want to find the `nvim-cmp` config, this lives in `lua/plugins/nvim-cmp.lua`. Other
plugins may not be named exactly as this example, but the name should be enough to find it.

