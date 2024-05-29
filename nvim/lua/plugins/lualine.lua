return {
	"nvim-lualine/lualine.nvim",
	enabled = true,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/tokyonight.nvim"
	},
	opts = {
		options = {
			theme = 'tokyonight',
		},
		sections = {
			lualine_b = { 'diff', 'diagnostics' },
			lualine_c = { { 'filename', path = 3, } },
		},
	},
}
