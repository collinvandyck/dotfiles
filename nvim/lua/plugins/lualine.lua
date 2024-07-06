return {
	"nvim-lualine/lualine.nvim",
	enabled = true,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/tokyonight.nvim"
	},
	config = function()
		require('lualine').setup({
			options = {
				icons_enabled = true,
				theme = 'tokyonight',
				component_separators = { left = '', right = '' },
				section_separators = { left = '', right = '' },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = false,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				}
			},
			sections = {
				lualine_a = {
					{ 'mode', fmt = function(str) return str:sub(1, 2) end },
				},
				lualine_b = { 'diagnostics' },
				lualine_c = { {
					'filename', path = 3,
				} },
				lualine_x = { 'encoding', 'fileformat', 'filetype', function()
					local vals = {}
					local tw = vim.api.nvim_buf_get_option(0, 'textwidth');
					if tw > 0 then
						table.insert(vals, 'tw=' .. tostring(tw))
					end
					local et = vim.api.nvim_buf_get_option(0, 'expandtab');
					if et then
						table.insert(vals, 'et')
					end
					local wrap = vim.api.nvim_win_get_option(0, 'wrap');
					if wrap then
						table.insert(vals, 'wrap')
					end
					local so = vim.wo.scrolloff
					if so < 0 then
						so = vim.o.scrolloff -- get global option
					end
					table.insert(vals, 'so=' .. tostring(so))
					return table.concat(vals, ' ')
				end },
				lualine_y = { 'progress' },
				lualine_z = { 'location' }
			},
			tabline = {
				lualine_a = {
					{
						'tabs',
						max_length = vim.o.columns,
						mode = 2,
						path = 1,
					},
				},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {}
			},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
