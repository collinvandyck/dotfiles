return {
	"ahmedkhalf/project.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		require("project_nvim").setup {
			-- rules applied in order
			patterns = {
				".git",
				"Cargo.toml",
				"!=rust-learning",
				"_darcs",
				".hg",
				".bzr",
				".svn",
				"Makefile",
				"package.json",
			},
		}
		require("telescope").load_extension("projects")
	end
}
