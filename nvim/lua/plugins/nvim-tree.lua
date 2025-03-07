local function on_attach(bufnr)
	local api = require "nvim-tree.api"
	local function opts(desc)
		return {
			desc = "nvim-tree: " .. desc,
			buffer = bufnr,
			noremap = true,
			silent = true,
			nowait = true
		}
	end
	-- default mappings
	api.config.mappings.default_on_attach(bufnr)
	-- custom mappings
	-- vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent, opts('Up'))
	vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
	-- vim.keymap.set('n', 'Q', ':qa!<CR>', opts('Quit All'))
	vim.keymap.set('n', 'F', function()
		api.tree.toggle()
		vim.cmd("wincmd =")
	end, opts('Toggle'))
end

return {
	"nvim-tree/nvim-tree.lua",
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("nvim-tree").setup({
			on_attach = on_attach,
			disable_netrw = false, -- setting this to true interferes with GBrowse.
			hijack_cursor = true,
			actions = {
				open_file = {
					resize_window = false,
					window_picker = { enable = false, },
				},
			},
			diagnostics = {
				enable = true,
				severity = { min = vim.diagnostic.severity.ERROR, },
			},
			filesystem_watchers = { enable = true, },
			filters = {
				dotfiles = false,
				-- NB: make sure to set this to true, especially for rust projects.
				-- otherwise, it will try to watch all the temp files in target.
				git_ignored = true,
				custom = { "target" },
			},
			git = {
				ignore = true,
				enable = true,
			},
			renderer = {
				symlink_destination = false,
				icons = {
					show = {
						git = false,
					},
				},
			},
			view = {
				width = 30,
			},
			-- these settings are to make nvim-tree play nice with project.nvim.
			sync_root_with_cwd = true,
			respect_buf_cwd = true,
			update_focused_file = {
				enable = true,
				update_root = {
					enable = true,
				},
			},
		})
	end,
}
