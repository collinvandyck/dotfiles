return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	init = function()
		require("tokyonight").setup({
			style = "night",
			on_colors = function(colors)
				colors.bg = "#0e0e13"
			end,
			lualine_bold = true,
		})
	end,
}
