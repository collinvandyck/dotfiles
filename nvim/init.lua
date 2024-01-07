-- disable lsp logging unless we need to troubleshoot
vim.lsp.set_log_level("off")
vim.opt.ai = true
vim.opt.autochdir = false
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.autowrite = true
vim.opt.background = 'dark'
vim.opt.cursorline = true
vim.opt.equalalways = false
vim.opt.expandtab = false
vim.opt.foldenable = false
vim.opt.hidden = true
vim.opt.history = 10000
vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.linebreak = true
vim.opt.mouse = 'n'
vim.opt.mousescroll = 'ver:1,hor:1'
vim.opt.number = true
vim.opt.numberwidth = 4
vim.opt.scrollback = 10000
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 4
vim.opt.sidescrolloff = 20
vim.opt.signcolumn = 'number'
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.statusline = ""
vim.opt.swapfile = false
vim.opt.tabstop = 4
-- recommended for nvim-tree
-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.opt.tw = 80

-- these affect hover states
vim.opt.timeoutlen = 500
vim.opt.updatetime = 100

vim.opt.wildignore:append('*.a')
vim.opt.wrap = false
vim.g.mapleader = " "
vim.g.maplocalleader = "-"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{
		"bluz71/vim-moonfly-colors",
		lazy = false,
		name = "moonfly",
		priority = 1000,
	},
	{
		"cpea2506/one_monokai.nvim",
		config = function()
			require("one_monokai").setup({
				-- your options
				transparent = true,
			})
		end,
	},
	{ "isobit/vim-caddyfile" },
	{ "preservim/nerdcommenter" },
	{ "folke/neoconf.nvim",     cmd = "Neoconf" },
	{ "folke/neodev.nvim" },
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		}
	},
	{
		"kevinhwang91/nvim-bqf",
		config = function() require('bqf').setup({}) end,
	},
	{
		'stevearc/aerial.nvim',
		opts = {},
		-- Optional dependencies
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons"
		},
		config = function()
			require("aerial").setup({
				layout = {
					--default_direction = "right",
					--placement = "edge",
				},
				attach_mode = "global",
				highlight_on_jump = false,
				filter_kind = {
					['_'] = {
						"Class",
						"Constructor",
						"Enum",
						"Function",
						"Interface",
						"Module",
						"Method",
						"Struct",
					}
				},
			})
		end,
	},
	{ "nvim-telescope/telescope-ui-select.nvim", },
	{
		"nvim-tree/nvim-web-devicons",
		config = function()
			require 'nvim-web-devicons'.setup {
				override_by_extension = {
					["rs"] = {
						icon = "🦀",
					}
				},
			}
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"folke/tokyonight.nvim"
		},
		config = function()
			require('lualine').setup({
				options = {
					theme = 'tokyonight',
				},
				sections = {
					lualine_b = { 'branch', 'diff', 'diagnostics' },
					lualine_c = { { 'filename', path = 3, } },
				},
			})
		end,
	},
	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},
	{ "tpope/vim-fugitive", },
	{ "tpope/vim-rhubarb", },
	{
		"Canop/nvim-bacon",
		config = function()
			require("bacon").setup({
				quickfix = {
					enabled = false, -- true to populate the quickfix list with bacon errors and warnings
					event_trigger = true, -- triggers the QuickFixCmdPost event after populating the quickfix list
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"HiPhish/nvim-ts-rainbow2",
		},
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			configs.setup({
				ensure_installed = {},
				sync_install = false,
				auto_install = true,
				ignore_install = {},
				highlight = {
					enable = true,
					disable = {},
					additional_vim_regex_highlighting = false,
				},
				incremental_selection = {
					enable = true,
					keymaps = {
						node_incremental = "=",
						scope_incremental = "+",
						node_decremental = "-",
					},
				},
				rainbow = {
					enable = true,
					-- list of languages you want to disable the plugin for
					-- disable = { 'jsx', 'cpp' },
					-- Which query to use for finding delimiters
					query = 'rainbow-parens',
					-- Highlight the entire buffer all at once
					strategy = require('ts-rainbow').strategy.global,
				}
			})
		end
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
			require 'treesitter-context'.setup {
				enable = false, -- Enable this plugin (Can be enabled/disabled later via commands)
				max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to show for a single context
				trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
				separator = '─',
				zindex = 20,  -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			}
		end
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("ibl").setup {
				scope = { enabled = false },
			}
		end,
	},
	{
		"junegunn/fzf",
		build = function() vim.call("fzf#install") end
	},
	{
		"junegunn/fzf.vim",
		config = function()
			vim.g.fzf_layout = { window = { width = 1, height = 1 } }
			vim.g.fzf_preview_window = { 'right:50%', 'ctrl-/' }
			vim.g.fzf_buffers_jump = 1

			function _G.RipgrepFzf(query, fullscreen)
				print('RipgrepFzf query:', vim.fn.shellescape(query))
				local command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
				local initial_command = string.format(command_fmt, vim.fn.shellescape(query))
				local reload_command = string.format(command_fmt, '{q}')
				local spec = { options = { '--phony', '--print-query', '--query', query, '--bind', 'change:reload:' .. reload_command } }
				vim.call('fzf#vim#grep', initial_command, 1, vim.call('fzf#vim#with_preview', spec), fullscreen)
			end

			vim.cmd("command! -nargs=* -bang RG lua RipgrepFzf(<q-args>, <bang>0)")
		end
	},
	{ "nvim-lua/plenary.nvim", },
	{
		"folke/trouble.nvim",
		config = function()
			require("trouble").setup {
				position = "bottom", -- position of the list can be: bottom, top, left, right
				height = 20, -- height of the trouble list when position is top or bottom
				width = 50, -- width of the list when position is left or right
				icons = true, -- use devicons for filenames
				mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
				fold_open = "", -- icon used for open folds
				fold_closed = "", -- icon used for closed folds
				group = true, -- group results by file
				padding = true, -- add an extra new line on top of the list
				action_keys = { -- key mappings for actions in the trouble list
					-- map to {} to remove a mapping
					close = "q", -- close the list
					cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
					refresh = "r", -- manually refresh
					jump = { "<cr>", "<tab>" }, -- jump to the diagnostic or open / close folds
					open_split = { "<c-x>" }, -- open buffer in new split
					open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
					open_tab = { "<c-t>" }, -- open buffer in new tab
					jump_close = { "o" }, -- jump to the diagnostic and close the list
					toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
					toggle_preview = "P", -- toggle auto_preview
					hover = "K", -- opens a small popup with the full multiline message
					preview = "p", -- preview the diagnostic location
					close_folds = { "zM", "zm" }, -- close all folds
					open_folds = { "zR", "zr" }, -- open all folds
					toggle_fold = { "zA", "za" }, -- toggle fold of current file
					previous = "k", -- previous item
					next = "j" -- next item
				},
				indent_lines = true, -- add an indent guide below the fold icons
				auto_open = false, -- automatically open the list when you have diagnostics
				auto_close = false, -- automatically close the list when you have no diagnostics
				auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
				auto_fold = false, -- automatically fold a file trouble list at creation
				auto_jump = { "lsp_definitions" }, -- for the given modes, automatically jump if there is only a single result
				signs = {
					-- icons / text used for a diagnostic
					error = "",
					warning = "",
					hint = "",
					information = "",
					other = "﫠"
				},
				use_diagnostic_signs = true -- enabling this will use the signs defined in your lsp client
			}
		end
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = '0.1.5',
		dependencies = {
			"stevearc/aerial.nvim",
		},
		config = function()
			local actions = require("telescope.actions")
			local action_state = require('telescope.actions.state')
			local trouble = require("trouble.providers.telescope")

			require('telescope').setup {
				defaults = {
					layout_strategy = "vertical",
					layout_config = {
						vertical = {
							width = 0.95,
							height = 0.95,
							preview_width = 0.95,
						},
					},
					-- todo: need to get ctrl-p/ctrl-n mappings to choose items
					mappings = {
						i = {
							["<esc>"] = actions.close,
							["<C-u>"] = false, -- enable clearing prompt
							["<C-t>"] = trouble.open_with_trouble,
							["<C-k>"] = actions.move_selection_previous,
							["<C-p>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,
							["<C-n>"] = actions.move_selection_next,
						},
						n = {
							["<C-t>"] = trouble.open_with_trouble,
							["<C-k>"] = actions.move_selection_previous,
							["<C-p>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,
							["<C-n>"] = actions.move_selection_next,
						},
					}
				},
				pickers = {
					find_files = {},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown {}
					},
					aerial = {
						-- Display symbols as <root>.<parent>.<symbol>
						show_nesting = {
							["_"] = false, -- This key will be the default
							json = true, -- You can set the option for specific filetypes
							yaml = true,
						},
					},
				},
			}
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("aerial")
		end
	},
	{
		"ojroques/nvim-osc52",
		config = function()
			require('osc52').setup {
				max_length = 0, -- Maximum length of selection (0 for no limit)
				silent     = false, -- Disable message on successful copy
				trim       = false, -- Trim surrounding whitespaces before copy
			}
			local function copy()
				if vim.v.event.operator == 'y' then
					require('osc52').copy_register(vim.v.event.regname)
				end
			end
			vim.api.nvim_create_autocmd('TextYankPost', { callback = copy })
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				disable_netrw = false, -- setting this to true interferes with GBrowse.
				actions = {
					open_file = {
						resize_window = false,
						window_picker = { enable = false, },
					},
				},
				diagnostics = {
					enable = true,
					severity = { min = vim.diagnostic.severity.ERROR, },
				},
				filesystem_watchers = { enable = true, },
				filters = { dotfiles = false, },
				git = {
					ignore = true,
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
					width = {
						min = 40,
						max = 80,
						padding = 1,
					},
					centralize_selection = true,
				},
			})
		end,

	},
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function() require("mason").setup({}) end
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function() require("mason-lspconfig").setup({}) end
	},
	{
		"j-hui/fidget.nvim",
		config = function() require("fidget").setup {} end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"cmp"
		},
		config = function()
			local lsp_util = require "lspconfig/util"
			local telescope = require 'telescope.builtin'
			local trouble = require 'trouble.providers.telescope'
			local custom_attach = function(client, bufnr)
				local bufopts = { noremap = true, silent = true, buffer = bufnr }
				local show_help = function()
					vim.diagnostic.open_float(nil, { focus = false })
				end
				vim.api.nvim_create_autocmd({ "BufWritePre" }, {
					buffer = bufnr,
					callback = function()
						vim.api.nvim_command("silent! lua require('vim.lsp.buf').format(nil, 10000)")
						vim.api.nvim_command(
							"silent! lua require('vim.lsp.buf').code_action({ context = { only = { 'source.organizeImports' } }, apply = true})")
					end,
				})
				vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
					buffer = bufnr,
					callback = function()
						vim.api.nvim_command("silent! lua require('vim.lsp.buf').document_highlight()")
					end,
				})
				vim.api.nvim_create_autocmd({ "CursorMoved" }, {
					buffer = bufnr,
					callback = function()
						vim.api.nvim_command("silent! lua require('vim.lsp.buf').clear_references()")
					end,
				})
				vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
				vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
				vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)
				vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)
				vim.keymap.set('n', 'gd', '<cmd>Trouble lsp_definitions<CR>', bufopts)
				vim.keymap.set('n', 'gr', '<cmd>Trouble lsp_references<CR>', bufopts)
				vim.keymap.set('n', 'gs', telescope.lsp_document_symbols, bufopts)
				vim.keymap.set('n', 'gS', telescope.lsp_workspace_symbols, bufopts)
				vim.keymap.set('n', 'gi', '<cmd>Trouble lsp_implementations<CR>', bufopts)
				vim.keymap.set('n', 'gI', telescope.lsp_incoming_calls, bufopts)
				vim.keymap.set('n', 'gO', telescope.lsp_outgoing_calls, bufopts)
				vim.keymap.set('n', 'gh', show_help, bufopts)
				vim.keymap.set('n', 'g]', vim.diagnostic.goto_next, bufopts)
				vim.keymap.set('n', 'g[', vim.diagnostic.goto_prev, bufopts)
				vim.keymap.set('n', '<leader>gw', vim.lsp.buf.document_symbol, bufopts)
				vim.keymap.set('n', '<leader>gW', vim.lsp.buf.workspace_symbol, bufopts)
				vim.keymap.set('n', '<leader>ah', vim.lsp.buf.hover, bufopts)
				vim.keymap.set('n', '<leader>af', vim.lsp.buf.code_action, bufopts)
				vim.keymap.set('n', '<leader>ar', vim.lsp.buf.rename, bufopts)
				vim.keymap.set('n', '<leader>ai', vim.lsp.buf.incoming_calls, bufopts)
				vim.keymap.set('n', '<leader>ao', vim.lsp.buf.outgoing_calls, bufopts)
			end
			vim.cmd [[autocmd! ColorScheme * highlight NormalFloat guifg=white guibg=#1f2335]]
			vim.cmd [[autocmd! ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]]
			local handlers_border = {
				{ "🭽", "FloatBorder" },
				{ "▔", "FloatBorder" },
				{ "🭾", "FloatBorder" },
				{ "▕", "FloatBorder" },
				{ "🭿", "FloatBorder" },
				{ "▁", "FloatBorder" },
				{ "🭼", "FloatBorder" },
				{ "▏", "FloatBorder" },
			}
			local handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = handlers_border }),
				["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help,
					{ border = handlers_border }),
			}
			local capabilities = require('cmp_nvim_lsp').default_capabilities()
			require("lspconfig").lua_ls.setup({
				capabilities = capabilities,
				handlers = handlers,
				on_attach = custom_attach,
				settings = {
					Lua = {
						diagnostics = {
							globals = { 'vim' }
						},
					},
				},
			})
			require 'lspconfig'.tsserver.setup {
				capabilities = capabilities,
				handlers = handlers,
				on_attach = custom_attach,
			}
			require("lspconfig").gopls.setup({
				capabilities = capabilities,
				handlers = handlers,
				on_attach = custom_attach,
				cmd = { "gopls", "serve" },
				root_dir = lsp_util.root_pattern("go.work", "go.mod", ".git"),
				settings = {
					semanticTokens = true,
					usePlaceholders = false,
				},
			})
			require("lspconfig").rust_analyzer.setup({
				capabilities = capabilities,
				handlers = handlers,
				on_attach = custom_attach,
				on_init = function(client)
					local cargo = {}
					local check = {
						extraArgs = {
							"--target-dir",
							"target/rust-analyzer",
						},
					}
					local rustfmt = { extraArgs = { "+nightly" }, }
					local diagnostics = { enable = true, }
					local inlay_hints = { enabled = true, }
					-- RA_TARGET=x86_64-pc-windows-gnu neovim
					local ra_target = os.getenv("RA_TARGET")
					if ra_target then
						cargo.target = ra_target
						table.insert(check.extraArgs, "--target")
						table.insert(check.extraArgs, ra_target)
					end
					local ra_settings = {
						cargo = cargo,
						check = check,
						inlay_hints = inlay_hints,
						diagnostics = diagnostics,
						rustfmt = rustfmt,
					}
					client.config.settings = {
						['rust-analyzer'] = ra_settings,
					}
					client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
				end,
			})
		end
	},
	{
		"hrsh7th/nvim-cmp",
		name = "cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			{
				"L3MON4D3/LuaSnip",
				dependencies = { "rafamadriz/friendly-snippets" },
			},
			"saadparwaiz1/cmp_luasnip",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("luasnip.loaders.from_vscode").load {
				include = { "rust" },
			}
			local cmp = require('cmp')
			local luasnip = require("luasnip")
			local has_words_before = function()
				unpack = unpack or table.unpack
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0 and
					vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end
			cmp.setup({
				enabled = function()
					-- disable completion in comments
					local context = require 'cmp.config.context'
					-- keep command mode completion enabled when cursor is in a comment
					if vim.api.nvim_get_mode().mode == 'c' then
						return true
					else
						return not context.in_treesitter_capture("comment")
							and not context.in_syntax_group("Comment")
					end
				end,
				sources = cmp.config.sources({
					{ name = 'copilot' },
				}, {
					{ name = 'nvim_lsp' },
					{ name = 'nvim_lsp_signature_help' },
				}, {
					--					{ name = 'luasnip' },
					--				}, {
					{ name = 'buffer' },
				}),
				snippet = {
					expand = function(args)
						require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					format = function(entry, item)
						item.menu = ({
							buffer = "[Buffer]",
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							neorg = "[Neorg]",
							copilot = "[Copilot]",
						})[entry.source.name]
						return item
					end,
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						-- require("copilot_cmp.comparators").prioritize,

						-- Below is the default comparitor list and order for nvim-cmp
						cmp.config.compare.offset,
						-- cmp.config.compare.scopes, --this is commented in nvim-cmp too
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				mapping = cmp.mapping.preset.insert({
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					['<CR>'] = cmp.mapping.confirm({ select = true }),
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							if #cmp.get_entries() == 1 then
								cmp.confirm({ select = true })
							else
								cmp.select_next_item()
							end
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						elseif has_words_before() then
							cmp.complete()
						else
							fallback()
						end
					end, { "i", "s" }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
			})
			-- `/` cmdline setup.
			cmp.setup.cmdline({ '/', '?' }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp_document_symbol' }
				}, {
					{ name = 'buffer' }
				})
			})
			-- `:` cmdline setup.
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = 'path' }
				}, {
					{
						name = 'cmdline',
						option = {
							ignore_cmds = { 'Man', '!' }
						}
					}
				})
			})
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		enabled = false,
		config = function()
			-- https://github.com/zbirenbaum/copilot-cmp?tab=readme-ov-file
			-- recommended for copilot-cmp to work.
			require("copilot").setup({
				suggestion = { enabled = false },
				panel = { enabled = false },
			})
		end
	},
	{
		"zbirenbaum/copilot-cmp",
		enabled = false,
		config = function()
			require("copilot_cmp").setup()
		end
	},
	{
		"akinsho/toggleterm.nvim",
		config = function()
			require("toggleterm").setup {
				size = function(term)
					if term.direction == "horizontal" then
						return vim.o.rows * 0.9
					elseif term.direction == "vertical" then
						return vim.o.columns * 0.9
					end
				end,
				open_mapping = [[<c-t>]],
				hide_numbers = true, -- hide the number column in toggleterm buffers
				shade_filetypes = {},
				shade_terminals = true,
				shading_factor = '3', -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
				start_in_insert = true,
				insert_mappings = true, -- whether or not the open mapping applies in insert mode
				terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
				persist_size = true,
				direction = 'float',
				close_on_exit = true, -- close the terminal window when the process exits
				shell = 'zsh', -- change the default shell
				-- This field is only relevant if direction is set to 'float'
				float_opts = {
					-- The border key is *almost* the same as 'nvim_open_win'
					-- see :h nvim_open_win for details on borders however
					-- the 'curved' border is a custom border type
					-- not natively supported but implemented in this plugin.
					border = 'double',
					--  winblend = 3,
				}
			}
			function _G.set_terminal_keymaps()
				local opts = { noremap = true }
				vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
				--vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
				--vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
				--vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
				--vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
				--vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
			end

			-- if you only want these mappings for toggle term use term://*toggleterm#* instead
			vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
		end,
	},
})

-- important to set this after lazy has finished loading
-- vim.cmd('colorscheme moonfly')
vim.cmd('colorscheme tokyonight-night')

vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

-- mappings
local map = vim.api.nvim_set_keymap

-- q leader key maps
function toggle_quickfix()
	local windows = vim.fn.getwininfo()
	for _, win in pairs(windows) do
		if win["quickfix"] == 1 then
			vim.cmd.cclose()
			return
		end
	end
	vim.cmd.copen()
end

map('n', '<Leader>i', '<cmd>lua toggle_quickfix()<CR>', { noremap = true, silent = true })
map('n', 'qi', '<cmd>lua toggle_quickfix()<CR>', { noremap = true, silent = true })
map('n', 'qg', ':Telescope live_grep<CR>', { noremap = true })
map('n', '<C-j>', ':cn<CR>', { noremap = true, silent = true })
map('n', '<C-k>', ':cp<CR>', { noremap = true, silent = true })

-- treesitter
vim.keymap.set("n", "[c", function()
	require("treesitter-context").go_to_context()
end, { silent = true })

-- abbreviations
vim.api.nvim_command('iabbrev adn and')
vim.api.nvim_command('iabbrev waht what')
vim.api.nvim_command('iabbrev tehn then')
vim.api.nvim_command('iabbrev reutrn return')
vim.api.nvim_command('iabbrev reutnr return')

-- osc52 copy to clipboard
-- vim.keymap.set('n', '<leader>c', require('osc52').copy_operator, {expr = true })
-- vim.keymap.set('n', '<leader>cc', '<leader>c_', {remap = true})
-- vim.keymap.set('v', '<leader>c', require('osc52').copy_visual)

map('n', ',', 'zz', { noremap = true })
map('n', '<M-i>', 'zt', { noremap = true })
map('n', '<M-b>', ':BaconLoad<CR>:BaconNext<CR>', { noremap = true })
map('n', '<C-g>', ':GFiles<CR>', { noremap = true })
map('n', '<C-h>', ':History<CR>', { noremap = true })
map('n', '<C-p>', ':Files<CR>', { noremap = true })
map('n', '<C-s>', ':wa!<CR>', { noremap = true })
map('n', '<C-w>t', ':tabnew %<CR>', { noremap = true })
map('n', '<Leader>gb', ':Git blame<CR>', { noremap = true })
map('n', '<Leader>h', ':vertical res -5<CR>', { noremap = true })
map('n', '<Leader>j', ':res +5<CR>', { noremap = true })
map('n', '<Leader>k', ':res -5<CR>', { noremap = true })
map('n', '<Leader>l', ':vertical res +5<CR>', { noremap = true })
map('n', '<Leader>N', ':noh<CR>', { noremap = true })
map('n', '<Leader>q', ':q!<CR>', { noremap = true })
map('n', '<Leader>Q', ':qa!<CR>', { noremap = true })
map('n', '<Leader>rl', ':silent! bufdo e<CR>:LspRestart<CR>', { noremap = true })
map('n', '<Leader>r', ':LspRestart<CR>', { noremap = true })
map('n', '<Leader>s', ':RG<CR>', { noremap = true })
map('n', '<Leader>t', ':tabnew %<CR>', { noremap = true })
map('n', '<Leader>w', ':Windows<CR>', { noremap = true })
map('n', '<Leader>W', ':set wrap!<CR>', { noremap = true })
map('n', '<leader>ve', ':e $MYVIMRC<CR>', { noremap = true })
map('n', '<leader>R', ':source $MYVIMRC<CR>', { noremap = true })
map('n', '<Leader>f', ':NvimTreeFindFile<CR>', { noremap = true })
map('n', '<Leader>n', ':NvimTreeToggle<CR>zz<C-w>=', { noremap = true })
map('n', '<Leader>xx', ':TroubleToggle<CR>', { noremap = true })
map('n', '<Leader>xw', ':TroubleToggle workspace_diagnostics<CR>', { noremap = true })
map('n', '<Leader>xd', ':TroubleToggle document_diagnostics<CR>', { noremap = true })
map('n', '<Leader>xq', ':TroubleToggle quickfix<CR>', { noremap = true })
map('n', '<Leader>xl', ':TroubleToggle loclist<CR>', { noremap = true })
map('n', '<Leader>xr', ':TroubleToggle lsp_references<CR>', { noremap = true })
map('n', 'tn', ':tabnext<CR>', { noremap = true })
map('n', 'tp', ':tabprevious<CR>', { noremap = true })
map('n', 'T', ':Telescope<CR>', { noremap = true })
map('n', 'n', 'nzz', { noremap = true })
map('n', 'N', 'Nzz', { noremap = true })
map('n', '*', '*zz', { noremap = true })
map('n', '#', '#zz', { noremap = true })
map('n', 'ge', '<cmd>AerialToggle<CR>', { noremap = true })
map('n', 'g*', 'g*zz', { noremap = true })
map('n', 'g#', 'g#zz', { noremap = true })
map('i', 'jk', '<esc>', { noremap = true })
map('i', '<c-s>', '<esc>:wa!<CR>', { noremap = true })
map('i', '<C-E>', '<esc>A', { noremap = true })
map('c', '<c-a>', '<Home>', { noremap = true })
map('t', '<Esc>', '<C-\\><C-n>', { noremap = true })
map('n', '<ScrollWheelLeft>', '<nop>', { noremap = true })
map('n', '<ScrollWheelRight>', '<nop>', { noremap = true })



-- autocommand examples
-- VimEnter: when we enter vim for the first time.
--[[
vim.api.nvim_create_augroup("Startup", {clear=true})
vim.api.nvim_create_autocmd({"VimEnter"}, {
	group = "Startup",
	pattern = {"*"},
	callback = function(ev)
		local bufnr = vim.api.nvim_get_current_buf()
		local buf_name = vim.api.nvim_buf_get_name(bufnr)
		local buf_line_count = vim.api.nvim_buf_line_count(bufnr)

		if buf_name == "" and buf_line_count == 1 then
			vim.cmd("silent! NvimTreeToggle")
			vim.cmd("wincmd l")
		end
	end,
})
--]]

--[[
-- Always toggle nvimtree when creating a new tab
vim.api.nvim_create_augroup("TabNew", {clear=true})
vim.api.nvim_create_autocmd({"TabNew"}, {
	group = "TabNew",
	pattern = {"*"},
	callback = function(ev)
		vim.cmd("silent! NvimTreeToggle")
	end,
})


vim.api.nvim_create_augroup("CommandLine", {clear=true})
vim.api.nvim_create_autocmd({"CmdlineLeave"}, {
	group = "CommandLine",
	pattern = {"*"},
	callback = function(ev)
		vim.defer_fn( function()vim.cmd('echom ""') end, 3000)
	end,
})

--]]
