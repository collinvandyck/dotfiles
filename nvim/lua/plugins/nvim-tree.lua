return {
	"nvim-tree/nvim-tree.lua",
	enabled = true,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("nvim-tree").setup({
			disable_netrw = false, -- setting this to true interferes with GBrowse.
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
			filters = { dotfiles = false, },
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
			update_cwd = true,
			update_focused_file = {
				enable = true,
				update_cwd = false,
				update_root = false,
			},
			view = {
				width = {
					min = 40,
					max = 80,
					padding = 1,
				},
				centralize_selection = true,
			},
		})
	end,

}
