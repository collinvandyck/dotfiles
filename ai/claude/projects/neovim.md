In this project I will ask you questions about my neovim configuration.

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
Each of these plugins uses the Lazy plugin loading system.

Each file inside of lua/plugins is named for the plugin that it represents, and the contents of each
file initializes that plugin.

