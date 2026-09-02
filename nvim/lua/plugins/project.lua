return {
	"collinvandyck/project.nvim",
	config = function()
		require("project_nvim").setup {
			detection_methods = { "pattern" },

			-- rules applied in order
			patterns = {
				".git",
			},

			exclude_dirs = {
				"/tmp/*",
				"/private/tmp/*",
				"~/.dotfiles/*",
				"~/code/rust-learning/*",
			},

			-- for debugging
			silent_chdir = true,
		}
	end
}
