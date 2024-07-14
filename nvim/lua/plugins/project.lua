return {
	"collinvandyck/project.nvim",
	enabled = false,
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
			},

			-- for debugging
			silent_chdir = true,
		}
	end
}
