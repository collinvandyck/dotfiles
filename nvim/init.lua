require("init")

-- disable lsp logging unless we need to troubleshoot
vim.lsp.set_log_level("off")

vim.opt.ai = true
vim.opt.autochdir = false
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.background = 'dark'
vim.opt.cursorline = true
vim.opt.equalalways = false
vim.opt.expandtab = false
vim.opt.foldenable = false
vim.opt.hidden= true
vim.opt.history= 10000
vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.linebreak = true
vim.opt.mouse = 'n'
vim.opt.number = true
vim.opt.numberwidth = 4
vim.opt.scrollback = 10000
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 4
vim.opt.sidescrolloff = 20
vim.opt.signcolumn = 'number'
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.statusline=""
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.timeoutlen = 500
vim.opt.wildignore:append('*.a')
vim.opt.wrap = false
vim.g.mapleader = " "
vim.g.maplocalleader = "-"

-- abbreviations
vim.api.nvim_command('iabbrev adn and')
vim.api.nvim_command('iabbrev waht what')
vim.api.nvim_command('iabbrev tehn then')
vim.api.nvim_command('iabbrev reutrn return')

-- mappings
local map = vim.api.nvim_set_keymap

-- osc52 copy to clipboard
vim.keymap.set('n', '<leader>c', require('osc52').copy_operator, {expr = true })
vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
vim.keymap.set('v', '<leader>c', require('osc52').copy_visual)

map('n', ',', 'zz', {noremap = true})
map('n', '<C-g>', ':GFiles<CR>', {noremap = true})
map('n', '<C-h>', ':History<CR>', {noremap = true})
map('n', '<C-p>', ':Files<CR>', {noremap = true})
map('n', '<C-s>', ':wa!<CR>', {noremap = true})
map('n', '<Leader>gb', ':Git blame<CR>', {noremap = true})
map('n', '<Leader>h', ':vertical res -5<CR>', {noremap = true})
map('n', '<Leader>i', ':ccl<CR>', {noremap = true})
map('n', '<Leader>j', ':res +5<CR>', {noremap = true})
map('n', '<Leader>k', ':res -5<CR>', {noremap = true})
map('n', '<Leader>l', ':vertical res +5<CR>', {noremap = true})
map('n', '<Leader>N', ':noh<CR>', {noremap = true})
map('n', '<Leader>q', ':q!<CR>', {noremap = true})
map('n', '<Leader>Q', ':qa!<CR>', {noremap = true})
map('n', '<Leader>rl', ':silent! bufdo e<CR>:LspRestart<CR>', {noremap = true})
map('n', '<Leader>s', ':RG<CR>', {noremap = true})
map('n', '<Leader>t', ':tabnew %<CR>', {noremap = true})
map('n', '<Leader>w', ':Windows<CR>', {noremap = true})
map('n', '<Leader>W', ':set wrap!<CR>', {noremap = true})
map('n', '<leader>ve', ':e $MYVIMRC<CR>' , {noremap = true})
map('n', '<leader>R', ':source $MYVIMRC<CR>' , {noremap = true})
map('n', '<Leader>n', ':NvimTreeToggle<CR>zz<C-w>=', {noremap = true})
map('n', '<Leader>xx', ':TroubleToggle<CR>', {noremap = true})
map('n', '<Leader>xw', ':TroubleToggle workspace_diagnostics<CR>', {noremap = true})
map('n', '<Leader>xd', ':TroubleToggle document_diagnostics<CR>', {noremap = true})
map('n', '<Leader>xq', ':TroubleToggle quickfix<CR>', {noremap = true})
map('n', '<Leader>xl', ':TroubleToggle loclist<CR>', {noremap = true})
map('n', '<Leader>xr', ':TroubleToggle lsp_references<CR>', {noremap = true})
map('n', 'tn', ':tabnext<CR>', {noremap = true})
map('n', 'tp', ':tabprevious<CR>', {noremap = true})
map('n', 'T', ':Telescope<CR>', {noremap = true})
map('n', 'n', 'nzz', {noremap=true})
map('n', 'N', 'Nzz', {noremap=true})
map('n', '*', '*zz', {noremap=true})
map('n', '#', '#zz', {noremap=true})
map('n', 'g*', 'g*zz', {noremap=true})
map('n', 'g#', 'g#zz', {noremap=true})
map('i', 'jk', '<esc>', {noremap = true})
map('i', '<c-s>', '<esc>:wa!<CR>', {noremap = true})
map('i', '<C-E>', '<esc>A', {noremap = true})
map('c', '<c-a>', '<Home>', {noremap = true})
map('t', '<Esc>', '<C-\\><C-n>', {noremap = true})

