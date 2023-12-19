local actions = require("telescope.actions")
local action_state = require('telescope.actions.state')
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
				--["<M-q>"] = actions.send_to_qflist,
			},
			n = {
				["<C-t>"] = trouble.open_with_trouble,
				--["<M-q>"] = actions.send_to_qflist,
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
		["ui-select"] = {
		  require("telescope.themes").get_dropdown {
			-- even more opts
		  }

		  -- pseudo code / specification for writing custom displays, like the one
		  -- for "codeactions"
		  -- specific_opts = {
		  --   [kind] = {
		  --     make_indexed = function(items) -> indexed_items, width,
		  --     make_displayer = function(widths) -> displayer
		  --     make_display = function(displayer) -> function(e)
		  --     make_ordinal = function(e) -> string
		  --   },
		  --   -- for example to disable the custom builtin "codeactions" display
		  --      do the following
		  --   codeactions = false,
		  -- }
		}
	},
}

require("telescope").load_extension("ui-select")

