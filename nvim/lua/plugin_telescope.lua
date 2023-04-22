local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")
require('telescope').setup{
	defaults = {
		layout_strategy = "vertical",
		layout_config = {
			vertical = {
				width = 0.95,
				height = 0.95,
				preview_width = 0.95,
			},
		},
		mappings = {
			i = {
				["<esc>"] = actions.close,
				["<C-u>"] = false, -- enable clearing prompt
				["<C-t>"] = trouble.open_with_trouble,
			},
			n = {
				["<C-t>"] = trouble.open_with_trouble,
			},
		}
	},
	pickers = {
		find_files = {
		},
		-- Default configuration for builtin pickers goes here:
		-- picker_name = {
		--   picker_config_key = value,
		--   ...
		-- }
		-- Now the picker_config_key will be applied every time you call this
		-- builtin picker
	},
	extensions = {
		-- Your extension configuration goes here:
		-- extension_name = {
		--   extension_config_key = value,
		-- }
		-- please take a look at the readme of the extension you want to configure
	}
}


