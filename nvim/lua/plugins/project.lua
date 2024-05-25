return {
	"ahmedkhalf/project.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("project_nvim").setup {
			detection_methods = { "lsp" },

			-- rules applied in order
			patterns = {
				"Cargo.toml",
			},

			-- for debugging
			silent_chdir = true,
		}
		require("telescope").load_extension("projects")
	end
}
