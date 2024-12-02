local toggle_quickfix = function()
	local windows = vim.fn.getwininfo()
	for _, win in pairs(windows) do
		if win["quickfix"] == 1 then
			vim.cmd.cclose()
			return
		end
	end
	vim.cmd.copen()
end

local toggle_scrolloff = function()
	local so = vim.api.nvim_get_option_value("scrolloff", {})
	if so == 35 then
		vim.opt.scrolloff = 5
	else
		vim.opt.scrolloff = 35
	end
	so = vim.api.nvim_get_option_value("scrolloff", {})
end

local git_commit_ci = function()
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
end

local indent_to_right_position = function()
	local cond = #vim.fn.getline(".") == 0
	if cond then
		return '"_cc'
	else
		return "i"
	end
end

local toggle_wrap = function()
	vim.wo.wrap = not vim.wo.wrap
end

local grep_code = function()
	local fzf = require("fzf-lua")
	fzf.live_grep({
		resume = false,
	})
end

--vim.keymap.set('n', '<Leader>F', ':NvimTreeToggle<CR>zz<C-w>=<C-w><C-w>', map_opts)
local tree_toggle = function()
	vim.notify("toggle")
	local api = require('nvim-tree.api')
	vim.cmd("NvimTreeToggle")
	if bufn then
		vim.api.nvim_set_current_buf(bufn)
		vim.cmd("wincmd =")
	end
end

local tree_find_file = function()
	local api = require('nvim-tree.api')
	local bufn = vim.api.nvim_get_current_buf()
	local is_open = api.tree.is_visible({ tabpage = vim.api.nvim_get_current_tabpage() })
	if is_open then
		local node = api.tree.get_node_under_cursor()
		if node then
			local path = node.absolute_path
			local bufpath = vim.api.nvim_buf_get_name(0)
			-- compare and do something differently possibly.
		end
	end
	api.tree.find_file({ open = true, focus = true })
end


local qf_nav = function(direction)
	local idx = vim.fn.getqflist({ idx = 0 }).idx
	local len = vim.fn.len(vim.fn.getqflist())
	if len == 0 then
		return
	end
	if direction == 'next' then
		if idx < len then
			vim.cmd('cn', { silent = true })
		end
	else
		if idx > 1 then
			vim.cmd('cp', { silent = true })
		end
	end
end

-- mappings
local map = vim.api.nvim_set_keymap
local map_opts = { noremap = true, silent = true }

map('n', '<M-i>', 'zt', map_opts)
map('n', '<M-b>', ':BaconLoad<CR>:BaconNext<CR>', map_opts)
map('n', '<C-w>t', ':tabnew %<CR>', map_opts)
map('n', '<Leader>gb', ':Git blame<CR>', map_opts)
map('n', '<Leader>h', ':vertical res -5<CR>', map_opts)
map('n', '<Leader>j', ':res +5<CR>', map_opts)
map('n', '<Leader>k', ':res -5<CR>', map_opts)
map('n', '<Leader>l', ':vertical res +5<CR>', map_opts)
map('n', '<Leader>N', ':noh<CR>', map_opts)
map('n', '<Leader>t', ':tabnew %<CR>', map_opts)
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
-- map('i', 'jk', '<esc>', map_opts)
map('i', '<C-E>', '<esc>A', map_opts)
map('c', '<c-a>', '<Home>', map_opts)
map('t', '<Esc>', '<C-\\><C-n>', map_opts)
map('n', '<ScrollWheelLeft>', '<nop>', map_opts)
map('n', '<ScrollWheelRight>', '<nop>', map_opts)
map('n', '<F3>', ':set hlsearch!<CR>', map_opts) -- toggle search highlighting with f3
map('i', '<Space>', '<Space><C-g>u', map_opts)   -- more granular undos

vim.keymap.set('n', '<C-j>', function() qf_nav('next') end, map_opts)
vim.keymap.set('n', '<C-k>', function() qf_nav('prev') end, map_opts)
vim.keymap.set('n', 'Q', ':qa!<CR>', map_opts)
vim.keymap.set('n', '<C-s>', ':wa!<CR>', map_opts)
vim.keymap.set('i', '<C-s>', '<C-\\><C-n>:wa!<CR>', map_opts)

local fzf = require("fzf-lua")

vim.keymap.set('n', '<leader>q', ':q!<CR>', map_opts)
vim.keymap.set('n', '<leader>Q', ':qa!<CR>', map_opts)
vim.keymap.set('n', '<leader>zf', fzf.builtin, map_opts)
vim.keymap.set('n', '<leader>fs', grep_code, { noremap = true })
vim.keymap.set('n', '<Leader>F', tree_toggle, map_opts)
vim.keymap.set('n', 'F', tree_find_file, map_opts)
vim.keymap.set('n', '<leader>fh', fzf.buffers, map_opts)
vim.keymap.set('n', '<leader>ft', fzf.tabs, map_opts)
vim.keymap.set('n', '<space>s', grep_code, { noremap = true })
vim.keymap.set('n', '<c-p>', fzf.files, { noremap = true })
vim.keymap.set('n', '<c-h>', fzf.buffers, { noremap = true })
vim.keymap.set('n', '<c-t>', fzf.tabs, { noremap = true })
vim.keymap.set('n', 'tci', git_commit_ci, { noremap = true })                                       -- runs 'git ci'
vim.keymap.set('n', '<leader>so', toggle_scrolloff, { noremap = true })                             -- toggle scrolloff
vim.keymap.set('n', '<Leader>i', toggle_quickfix, { noremap = true, silent = true })                -- toggle quickfix
vim.keymap.set('n', 'qi', toggle_quickfix, { noremap = true, silent = true })                       -- toggle quickfix
vim.keymap.set('n', 'i', indent_to_right_position, { desc = "Indent", silent = true, expr = true }) -- automatically indent to the appropriate position.
vim.keymap.set('n', 'x', '"_x', { noremap = true })                                                 -- delete single char without copying
vim.keymap.set('v', 'p', '"_dP', map_opts)                                                          -- keep last yanked when pasting
vim.keymap.set('n', '<leader>w', toggle_wrap, map_opts)
vim.keymap.set('n', '<leader>gs', ':Autosession search<cr>', map_opts)
vim.keymap.set('n', 'ya', ':%y<cr>', map_opts)
