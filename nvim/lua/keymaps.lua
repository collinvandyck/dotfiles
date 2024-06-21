-- q leader key maps
function ToggleQuickfix()
	local windows = vim.fn.getwininfo()
	for _, win in pairs(windows) do
		if win["quickfix"] == 1 then
			vim.cmd.cclose()
			return
		end
	end
	vim.cmd.copen()
end

-- mappings
local map = vim.api.nvim_set_keymap

map('n', '<Leader>i', '<cmd>lua ToggleQuickfix()<CR>', { noremap = true, silent = true })
map('n', 'qi', '<cmd>lua ToggleQuickfix()<CR>', { noremap = true, silent = true })
map('n', 'qg', ':Telescope live_grep<CR>', { noremap = true })
map('n', '<C-j>', ':cn<CR>', { noremap = true, silent = true })
map('n', '<C-k>', ':cp<CR>', { noremap = true, silent = true })
map('n', '<M-i>', 'zt', { noremap = true })
map('n', '<M-b>', ':BaconLoad<CR>:BaconNext<CR>', { noremap = true })
--map('n', '<C-g>', ':GFiles<CR>', { noremap = true })
map('n', '<C-s>', ':wa!<CR>', { noremap = true })
map('n', '<C-w>t', ':tabnew %<CR>', { noremap = true })
map('n', '<Leader>gb', ':Git blame<CR>', { noremap = true })
map('n', '<Leader>h', ':vertical res -5<CR>', { noremap = true })
map('n', '<Leader>j', ':res +5<CR>', { noremap = true })
map('n', '<Leader>k', ':res -5<CR>', { noremap = true })
map('n', '<Leader>l', ':vertical res +5<CR>', { noremap = true })
map('n', '<Leader>N', ':noh<CR>', { noremap = true })
map('n', '<Leader>q', ':q!<CR>', { noremap = true })
map('n', '<Leader>Q', ':qa!<CR>', { noremap = true })
map('n', '<Leader>rl', ':silent! bufdo e<CR>:LspRestart<CR>', { noremap = true })
map('n', '<Leader>r', ':LspRestart<CR>', { noremap = true })
map('n', '<Leader>s', ':RG<CR>', { noremap = true })
map('n', '<Leader>t', ':tabnew %<CR>', { noremap = true })
map('n', '<Leader>w', ':Windows<CR>', { noremap = true })
map('n', '<Leader>W', ':set wrap!<CR>', { noremap = true })
map('n', '<leader>ve', ':e $MYVIMRC<CR>', { noremap = true })
map('n', '<leader>R', ':source $MYVIMRC<CR>', { noremap = true })
map('n', '<Leader>f', ':NvimTreeFindFile<CR>', { noremap = true })
map('n', '<Leader>n', ':NvimTreeToggle<CR>zz<C-w>=', { noremap = true })
map('n', '<Leader>xx', ':TroubleToggle<CR>', { noremap = true })
map('n', '<Leader>xw', ':TroubleToggle workspace_diagnostics<CR>', { noremap = true })
map('n', '<Leader>xd', ':TroubleToggle document_diagnostics<CR>', { noremap = true })
map('n', '<Leader>xq', ':TroubleToggle quickfix<CR>', { noremap = true })
map('n', '<Leader>xl', ':TroubleToggle loclist<CR>', { noremap = true })
map('n', '<Leader>xr', ':TroubleToggle lsp_references<CR>', { noremap = true })
map('n', '<Leader>z', ':ZenMode<CR>', { noremap = true })
map('n', 'tn', ':tabnext<CR>', { noremap = true })
map('n', 'tp', ':tabprevious<CR>', { noremap = true })
map('n', 'T', ':Telescope<CR>', { noremap = true })
map('n', 'n', 'nzz', { noremap = true })
map('n', 'N', 'Nzz', { noremap = true })
map('n', '*', '*zz', { noremap = true })
map('n', '#', '#zz', { noremap = true })
map('n', 'ge', '<cmd>AerialToggle<CR>', { noremap = true })
map('n', 'g*', 'g*zz', { noremap = true })
map('n', 'g#', 'g#zz', { noremap = true })
map('i', 'jk', '<esc>', { noremap = true })
map('i', '<c-s>', '<esc>:wa!<CR>', { noremap = true })
map('i', '<C-E>', '<esc>A', { noremap = true })
map('c', '<c-a>', '<Home>', { noremap = true })
map('t', '<Esc>', '<C-\\><C-n>', { noremap = true })
map('n', '<ScrollWheelLeft>', '<nop>', { noremap = true })
map('n', '<ScrollWheelRight>', '<nop>', { noremap = true })


local fzf = require("fzf-lua")
map('n', '<C-f>', ":FzfLua<cr>", { noremap = true, desc = "Files" })
vim.keymap.set('n', '<C-p>', fzf.files, { noremap = true })
vim.keymap.set('n', '<C-h>', fzf.buffers, { noremap = true })
vim.keymap.set('n', '<space>s', function() fzf.live_grep({ resume = true }) end, { noremap = true })
vim.keymap.set('n', 'tci', function()
	local res = vim.fn.system("git ci")
	if vim.v.shell_error ~= 0 then
		-- Command failed, send a notification
		vim.notify("commit failed: " .. result, vim.log.levels.ERROR)
	else
		vim.notify("commit")
	end
end, { noremap = true })

-- toggle search highlighting with f3
map('n', '<F3>', ':set hlsearch!<CR>', { noremap = true })
-- more granular undos
map('i', '<Space>', '<Space><C-g>u', { noremap = true })
