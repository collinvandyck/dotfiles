return {
	"ibhagwan/fzf-lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("fzf-lua").setup({
			file_icon_padding = ' ', -- helps with kitty rendering
			lsp = {
				async_or_timeout = 10000,
			},
			winopts = {
				width = 0.95,
			}
		})
		-- Register FzfLua as vim.ui.select backend to suppress warnings
		require("fzf-lua").register_ui_select({ silent = true })
	end
}
