return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	init = function()
		require("tokyonight").setup({
			style = "night",
			on_colors = function(colors)
				-- Note: use :Inspect to find the highlight groups for a particular code block.
				-- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_night.lua
				-- https://mdigi.tools/lighten-color
				-- https://mdigi.tools/darken-color

				colors.bg = "#0e0e13"

				-- brighten the bg in visual mode
				colors.bg_visual = "#283457"
				colors.bg_visual = "#40538b"
			end,
			on_highlights = function(hl)
				-- darken the bg for the cursorline
				hl.CursorLine.bg = "#292e42"
				hl.CursorLine.bg = "#1f2231" -- 25% darker
				hl.CursorLine.bg = "#1d202e" -- 30% darker

				hl.Comment.fg = "#8a8a8a"
				hl.DiagnosticUnderlineHint.sp = "#8a8a8a"
				hl.DiagnosticUnnecessary.fg = "#8a8a8a"
				--hl.TabLine.fg = "#8a8a8a"

				-- this can be nil i think if copilot is not configured in nvim-cmp
				if hl.CmpItemKindCopilot then
					hl.CmpItemKindCopilot.fg = "#6CC644"
				end
			end,
			lualine_bold = true,
		})
	end,
}
