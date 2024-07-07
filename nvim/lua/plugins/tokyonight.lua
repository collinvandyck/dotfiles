return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	init = function()
		require("tokyonight").setup({
			style = "night",
			on_colors = function(colors)
				-- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_night.lua
				-- https://mdigi.tools/lighten-color
				-- https://mdigi.tools/darken-color

				colors.bg = "#0e0e13"

				-- brighten the bg in visual mode
				colors.bg_visual = "#283457"
				colors.bg_visual = "#40538b"
			end,
			on_highlights = function(highlights)
				-- darken the bg for the cursorline
				highlights.CursorLine.bg = "#292e42"
				highlights.CursorLine.bg = "#1f2231" -- 25% darker
				highlights.CursorLine.bg = "#1d202e" -- 30% darker
			end,
			lualine_bold = true,
		})
	end,
}
