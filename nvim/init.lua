vim.lsp.set_log_level("info")

vim.g.mapleader = ","
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
vim.opt.expandtab = true
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
vim.opt.timeoutlen = 1000
vim.opt.textwidth = 0
vim.opt.updatetime = 100
vim.opt.wildignore:append('*.a')
vim.opt.wrap = false
vim.opt.writebackup = false

require("plugs")                        -- not reloadable
vim.cmd("colorscheme tokyonight-night") -- set colorscheme after plugins loaded

local reloadable = {
	"commands",
	"abbreviations",
	"autocmds",
	"keymaps",
}
for _, mod in ipairs(reloadable) do
	require(mod)
end

-- reload everything that is reloadable
vim.keymap.set('n', '<leader>r', function()
	for _, mod in ipairs(reloadable) do
		package.loaded[mod] = nil
	end
	vim.cmd('source $MYVIMRC')
	vim.notify('reloaded!')
end, { noremap = true, silent = true })
