return {
	"echasnovski/mini.pairs",
	event = "VeryLazy",
	config = function()
		require("mini.pairs").setup({
			mappings = {
				["'"] = false,
			},
		})
	end,
}
