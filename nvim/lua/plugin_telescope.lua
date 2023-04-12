require('telescope').setup{
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    -- file_previewer = require'telescope.previewers'.cat.new,
    -- grep_previewer = require'telescope.previewers'.vimgrep.new,
    -- qflist_previewer = require'telescope.previewers'.qflist.new,
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
        -- map actions.which_key to <C-h> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
        ["<C-h>"] = "which_key"
      }
    }
  },
  pickers = {
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


