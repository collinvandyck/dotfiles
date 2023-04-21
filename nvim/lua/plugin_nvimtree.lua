-- recommended by the nvim-tree doco
-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1

require'nvim-tree'.setup {
  actions = {
	  open_file = {
		  resize_window = false,
		  window_picker = {
			  enable = false,
		  },
	  },
  },
  diagnostics = {
	  enable = true,
	  severity = {
		min = vim.diagnostic.severity.ERROR,
	  },
  },
  filesystem_watchers = {
	  enable = true,
  },
  filters = {
	  dotfiles = false,
  },
  git = {
	  ignore = false,
	  enable = false,
  },
  renderer = {
	  symlink_destination = false,
  },
  update_cwd = true,
  update_focused_file = {
    enable = true,
    update_cwd = false,
    update_root = false,
  },
  view = {
	width = 45,
    adaptive_size = false,
    centralize_selection = true,
	mappings = {
	  list = {
	    { key = "<C-t>", action = "" },
      },
	},
  },
}


