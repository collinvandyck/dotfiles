return {
	"nvim-tree/nvim-web-devicons",
	opts = {
		override_by_extension = {
			["rs"] = {
				icon = "🦀",
			},
			[".envrc"] = {
				icon = "",
				color = "#faf743",
				cterm_color = "227",
				name = "Envrc",
			},
		},
	}
}
