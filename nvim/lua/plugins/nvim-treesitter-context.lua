vim.keymap.set("n", "[c", function()
	require("treesitter-context").go_to_context()
end, { silent = true })

return {
	"nvim-treesitter/nvim-treesitter-context",
	opts = {
		enable = true,      -- Enable this plugin (Can be enabled/disabled later via commands)
		max_lines = 1,      -- How many lines the window should span. Values <= 0 mean no limit.
		min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
		line_numbers = true,
		multiline_threshold = 20, -- Maximum number of lines to show for a single context
		trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
		mode = 'cursor',    -- Line used to calculate context. Choices: 'cursor', 'topline'
		separator = '─',
		zindex = 20,        -- The Z-index of the context window
		on_attach = nil,    -- (fun(buf: integer): boolean) return false to disable attaching
	},
}
