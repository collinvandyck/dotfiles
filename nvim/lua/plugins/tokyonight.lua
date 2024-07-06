return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	init = function()
		require("tokyonight").setup({
			style = "night",
			on_colors = function(colors)
				colors.bg = "#15151e"
			end,
			lualine_bold = true,
		})
	end,
}
