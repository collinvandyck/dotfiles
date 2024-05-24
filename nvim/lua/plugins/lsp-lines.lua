-- https://git.sr.ht/~whynothugo/lsp_lines.nvim
return {
	enabled = false,
	"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
	config = function()
		vim.diagnostic.config({
			virtual_lines = { only_current_line = true },
			virtual_text = true,
		})
		require("lsp_lines").setup()
	end,
}
