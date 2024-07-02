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
local map_opts = { noremap = true, silent = true }

map('n', '<Leader>i', '<cmd>lua ToggleQuickfix()<CR>', map_opts)
map('n', 'qi', '<cmd>lua ToggleQuickfix()<CR>', map_opts)
map('n', '<C-j>', ':cn<CR>', map_opts)
map('n', '<C-k>', ':cp<CR>', map_opts)
map('n', '<M-i>', 'zt', map_opts)
map('n', '<M-b>', ':BaconLoad<CR>:BaconNext<CR>', map_opts)
map('n', '<C-w>t', ':tabnew %<CR>', map_opts)
map('n', '<Leader>gb', ':Git blame<CR>', map_opts)
map('n', '<Leader>h', ':vertical res -5<CR>', map_opts)
map('n', '<Leader>j', ':res +5<CR>', map_opts)
map('n', '<Leader>k', ':res -5<CR>', map_opts)
map('n', '<Leader>l', ':vertical res +5<CR>', map_opts)
map('n', '<Leader>N', ':noh<CR>', map_opts)
map('n', '<Leader>q', ':q!<CR>', map_opts)
map('n', '<Leader>Q', ':qa!<CR>', map_opts)
map('n', '<Leader>s', ':RG<CR>', map_opts)
map('n', '<Leader>t', ':tabnew %<CR>', map_opts)
map('n', '<Leader>w', ':Windows<CR>', map_opts)
map('n', '<Leader>W', ':set wrap!<CR>', map_opts)
map('n', '<Leader>f', ':NvimTreeFindFile<CR><C-w>=', map_opts)
map('n', '<Leader>F', ':NvimTreeToggle<CR>zz<C-w>=<C-w><C-w>', map_opts)
map('n', '<space>n', ':NvimTreeToggle<CR>zz<C-w>=', map_opts)
map('n', '<Leader>xx', ':TroubleToggle<CR>', map_opts)
map('n', '<Leader>xw', ':TroubleToggle workspace_diagnostics<CR>', map_opts)
map('n', '<Leader>xd', ':TroubleToggle document_diagnostics<CR>', map_opts)
map('n', '<Leader>xq', ':TroubleToggle quickfix<CR>', map_opts)
map('n', '<Leader>xl', ':TroubleToggle loclist<CR>', map_opts)
map('n', '<Leader>xr', ':TroubleToggle lsp_references<CR>', map_opts)
map('n', '<Leader>z', ':ZenMode<CR>', map_opts)
map('n', 'tn', ':tabnext<CR>', map_opts)
map('n', 'tp', ':tabprevious<CR>', map_opts)
map('n', 'n', 'nzz', map_opts)
map('n', 'N', 'Nzz', map_opts)
map('n', '*', '*zz', map_opts)
map('n', '#', '#zz', map_opts)
map('n', 'ge', '<cmd>AerialToggle<CR>', map_opts)
map('n', 'g*', 'g*zz', map_opts)
map('n', 'g#', 'g#zz', map_opts)
map('i', 'jk', '<esc>', map_opts)
map('i', '<C-E>', '<esc>A', map_opts)
map('c', '<c-a>', '<Home>', map_opts)
map('t', '<Esc>', '<C-\\><C-n>', map_opts)
map('n', '<ScrollWheelLeft>', '<nop>', map_opts)
map('n', '<ScrollWheelRight>', '<nop>', map_opts)

vim.keymap.set('n', 'Q', ':qa!<CR>', map_opts)
vim.keymap.set('n', '<C-s>', ':wa!<CR>', map_opts)
vim.keymap.set('i', '<C-s>', '<C-\\><C-n>:wa!<CR>', map_opts)

-- delete single character without pasting
-- vim.keymap.set('n', 'x', '"_x', { noremap = true })

-- keep last yanked when pasting
vim.keymap.set('v', 'p', '"_dP', map_opts)

-- automatically indent to the appropriate position.
vim.keymap.set('n', 'i', function()
	local cond = #vim.fn.getline(".") == 0
	if cond then
		return '"_cc'
	else
		return "i"
	end
end, { desc = "Automatically indent to the appropriate position", silent = true, expr = true })

local fzf = require("fzf-lua")
map('n', '<C-f>', ":FzfLua<cr>", { noremap = true, silent = true, desc = "Files" })
vim.keymap.set('n', '<C-p>', fzf.files, { noremap = true })
vim.keymap.set('n', '<C-h>', fzf.buffers, { noremap = true })
vim.keymap.set('n', '<space>s', function() fzf.live_grep({ resume = false }) end, { noremap = true })
vim.keymap.set('n', 'tci', function()
	local res = vim.fn.system("git ci")
	if vim.v.shell_error ~= 0 then
		if string.find(res, "nothing to commit") then
			vim.notify("nothing to commit")
		else
			vim.notify("commit failed: " .. res, vim.log.levels.ERROR)
		end
		return
	end
	vim.notify("commit")
end, { noremap = true })

-- toggle search highlighting with f3
map('n', '<F3>', ':set hlsearch!<CR>', map_opts)
-- more granular undos
map('i', '<Space>', '<Space><C-g>u', map_opts)

-- Meta-e will be the prefix for setting a lot of options. E: Editor. The meta
-- will not get in the way.

-- toggle scrolloff functions
vim.keymap.set('n', '<leader>so', function()
	local so = vim.api.nvim_get_option_value("scrolloff", {})
	if so == 35 then
		vim.opt.scrolloff = 5
	else
		vim.opt.scrolloff = 35
	end
	so = vim.api.nvim_get_option_value("scrolloff", {})
	vim.notify("so set to " .. tostring(so))
end, { noremap = true })
