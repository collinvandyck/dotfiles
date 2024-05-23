return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	init = function()
		require("tokyonight").setup({
			style = "night",
			colors = function(colors)
				-- colors.error = "#ff0000"
			end
		})
	end,
}
