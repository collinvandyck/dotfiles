return {
	'stevearc/dressing.nvim',
	opts = {},
	config = function()
		require('dressing').setup({
			input = {
				relative = "editor",
				win_options = {
					-- winhighlight = 'NormalFloat:DiagnosticError'
				}
			}
		})
	end
}
