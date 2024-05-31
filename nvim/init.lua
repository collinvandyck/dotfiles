vim.lsp.set_log_level("off")

vim.g.mapleader = " "
vim.g.maplocalleader = "-"
vim.opt.ai = true
vim.opt.autochdir = false
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.background = 'dark'
vim.opt.backup = false
vim.opt.cursorline = true
vim.opt.equalalways = false
vim.opt.expandtab = false
vim.opt.foldenable = false
vim.opt.hidden = true
vim.opt.history = 10000
vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.jumpoptions = 'stack'
vim.opt.linebreak = true
vim.opt.mouse = 'n'
vim.opt.mousescroll = 'ver:1,hor:1'
vim.opt.number = true
vim.opt.numberwidth = 4
vim.opt.scrollback = 10000
vim.opt.scrolloff = 35
vim.opt.startofline = false
vim.opt.shiftwidth = 4
vim.opt.sidescrolloff = 20
vim.opt.signcolumn = 'number'
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.statusline = ""
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.timeoutlen = 500
vim.opt.tw = 80
vim.opt.updatetime = 100
vim.opt.virtualedit = "block"
vim.opt.wildignore:append('*.a')
vim.opt.wrap = false
vim.opt.writebackup = false

require("plugs")
require("commands")
require("abbreviations")
require("autocmds")
require("colors")
require("keymaps")
