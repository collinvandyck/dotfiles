return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		{ "nushell/tree-sitter-nu" },

	},
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			ensure_installed = { "regex" },
			sync_install = false,
			auto_install = true,
			ignore_install = {},
			highlight = {
				enable = true,
				disable = {},
				additional_vim_regex_highlighting = false,
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					node_incremental = "=",
					scope_incremental = "+",
					node_decremental = "-",
				},
			},
		})
	end
}
