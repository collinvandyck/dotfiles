-- https://git.sr.ht/~whynothugo/lsp_lines.nvim
vim.diagnostic.config({
	virtual_lines = { only_current_line = true },
	virtual_text = true,
})
return {
	"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
	config = function()
		require("lsp_lines").setup()
	end,
}
