return {
	"L3MON4D3/LuaSnip",
	version = "v2.*",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	-- Disable submodules to avoid git submodule fetch issues
	-- jsregexp is optional and provides better performance, but not required
	build = (function()
		-- Only build jsregexp if on a Unix-like system and make is available
		if vim.fn.executable("make") == 1 then
			return "make install_jsregexp"
		end
		return nil
	end)(),
	config = function()
		--require("luasnip.loaders.from_vscode").load {
		--include = { "rust" },
		--}
		require("luasnip.loaders.from_vscode").lazy_load()
	end
}
