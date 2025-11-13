return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"cmp"
	},
	config = function()
		-- Delete default LSP keybindings to prevent conflicts
		pcall(vim.keymap.del, 'n', 'grr')
		pcall(vim.keymap.del, 'n', 'grn')
		pcall(vim.keymap.del, 'n', 'gri')
		pcall(vim.keymap.del, 'n', 'gra')
		pcall(vim.keymap.del, 'x', 'gra')

		local lsp_util = require "lspconfig/util"
		-- client, buffnr
		local custom_attach = function(_, bufnr)
			local bufopts = { noremap = true, silent = true, buffer = bufnr }
			local show_help = function()
				vim.diagnostic.open_float(nil, { focus = false })
			end
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				buffer = bufnr,
				callback = function()
					-- Organize imports for Go files
					if vim.bo.filetype == "go" then
						local clients = vim.lsp.get_active_clients({ bufnr = 0 })
						local client = clients[1]
						if client then
							local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
							params.context = { only = { "source.organizeImports" } }
							local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
							for cid, res in pairs(result or {}) do
								for _, r in pairs(res.result or {}) do
									if r.edit then
										local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
										vim.lsp.util.apply_workspace_edit(r.edit, enc)
									end
								end
							end
						end
					end
					-- Format the file
					local clients = vim.lsp.get_active_clients({ bufnr = 0 })
					for _, client in ipairs(clients) do
						if client.supports_method("textDocument/formatting") then
							vim.lsp.buf.format({ nil })
							return
						end
					end
				end,
			})
			--vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			--buffer = bufnr,
			--callback = function()
			--vim.api.nvim_command("silent! lua require('vim.lsp.buf').document_highlight()")
			--end,
			--})
			--vim.api.nvim_create_autocmd({ "CursorMoved" }, {
			--buffer = bufnr,
			--callback = function()
			--vim.api.nvim_command("silent! lua require('vim.lsp.buf').clear_references()")
			--end,
			--})
			local fzf = require("fzf-lua")
			local jump_opts = { jump1 = true, sync = false, silent = true }
			vim.keymap.set('n', 'gD', function() fzf.lsp_declarations(jump_opts) end, bufopts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
			-- Custom keymap to open hover in split
			vim.keymap.set('n', '<leader>K', function()
				local params = vim.lsp.util.make_position_params()
				vim.lsp.buf_request(0, 'textDocument/hover', params, function(err, result, ctx, config)
					if result and result.contents then
						local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
						local bufnr = vim.api.nvim_create_buf(false, true)
						vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
						vim.cmd('vsplit')
						vim.api.nvim_win_set_buf(0, bufnr)
						vim.bo[bufnr].filetype = 'markdown'
					end
				end)
			end, bufopts)
			vim.keymap.set('n', 'ga', fzf.lsp_code_actions, bufopts)
			vim.keymap.set('n', 'gt', function() fzf.lsp_typedefs(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gd', function() fzf.lsp_definitions(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gr', function()
				fzf.lsp_references({
					jump1 = true,
					sync = false,
					ignore_current_line = true,
					includeDeclaration = false,
				})
			end, bufopts)
			vim.keymap.set('n', 'gs', fzf.lsp_document_symbols, bufopts)
			vim.keymap.set('n', 'gw', fzf.lsp_live_workspace_symbols, bufopts)
			vim.keymap.set('n', 'gi', function() fzf.lsp_implementations(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gI', function() fzf.lsp_incoming_calls(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gO', function() fzf.lsp_outgoing_calls(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gh', show_help, bufopts)
			vim.keymap.set('n', 'gldd', fzf.diagnostics_document, bufopts)
			vim.keymap.set('n', 'gldw', fzf.diagnostics_workspace, bufopts)
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

		-- Enabled diagnostic severities (matching old behavior)
		local enabled_diag_sevs = {
			vim.diagnostic.severity.ERROR,
			vim.diagnostic.severity.WARN,
		}

		-- Configure diagnostics globally using vim.diagnostic.config (Neovim 0.11+)
		vim.diagnostic.config({
			underline = {
				severity = enabled_diag_sevs,
			},
			virtual_text = {
				spacing = 4,
				severity = enabled_diag_sevs,
			},
			signs = {
				severity = enabled_diag_sevs,
				text = {
					[vim.diagnostic.severity.ERROR] = 'E',
					[vim.diagnostic.severity.WARN] = 'W',
					[vim.diagnostic.severity.INFO] = 'I',
					[vim.diagnostic.severity.HINT] = 'H',
				},
			},
			update_in_insert = false,
		})

		local capabilities = require('cmp_nvim_lsp').default_capabilities()

		-- Use vim.lsp.config() API for Neovim 0.11+
		vim.lsp.config('lua_ls', {
			capabilities = capabilities,
			on_attach = custom_attach,
			settings = {
				Lua = {
					diagnostics = {
						globals = { 'vim' }
					},
				},
			},
		})

		vim.lsp.config('ts_ls', {
			capabilities = capabilities,
			on_attach = custom_attach,
		})

		vim.lsp.config('gopls', {
			capabilities = capabilities,
			on_attach = custom_attach,
			cmd = { "gopls", "serve" },
			root_dir = lsp_util.root_pattern("go.work", "go.mod", ".git"),
			settings = {
				semanticTokens = true,
				usePlaceholders = false,
			},
		})

		vim.lsp.config('pyright', {
			capabilities = capabilities,
			on_attach = custom_attach,
			settings = {
				pyright = {
					-- Using Ruff's import organizer
					disableOrganizeImports = true,
				},
				python = {
					analysis = {
						-- Ignore all files for analysis to exclusively use Ruff for linting
						ignore = { '*' },
					},
				},
			},
		})

		vim.lsp.config('ocamllsp', {
			capabilities = capabilities,
			on_attach = custom_attach,
		})

		vim.lsp.config('ruff', {
			capabilities = capabilities,
			on_attach = custom_attach,
		})

		vim.lsp.config('sourcekit', {
			capabilities = capabilities,
			on_attach = custom_attach,
		})

		vim.lsp.config('bashls', {
			capabilities = capabilities,
			on_attach = custom_attach,
			filetypes = { 'sh', 'bash', 'zsh' },
		})

		vim.lsp.config('rust_analyzer', {
			capabilities = capabilities,
			on_attach = custom_attach,
			settings = (function()
				local ra_settings = {
					cargo = {
						allFeatures = true,
					},
					check = {},
					diagnostics = {
						enable = true,
						experimental = {
							enable = false,
						},
					},
					rustfmt = {
						extraArgs = {
							"+nightly",
						},
					},
				}

				-- RA_TARGET=x86_64-pc-windows-gnu neovim
				local ra_target = os.getenv("RA_TARGET")
				if ra_target then
					require("notify")(ra_target)
					ra_settings.cargo.target = ra_target
					ra_settings.check = {
						extraArgs = {
							"--target",
							ra_target,
						},
					}
				end

				local settings = {
					['rust-analyzer'] = ra_settings,
				}
				--print(vim.inspect(settings));
				return settings
			end)(),
		})

		vim.lsp.config('zls', {
			capabilities = capabilities,
			on_attach = custom_attach,
		})

		vim.lsp.config('clojure_lsp', {
			capabilities = capabilities,
			on_attach = custom_attach,
			filetypes = { 'clojure', 'edn', 'clojurescript' },
		})

		-- Enable all configured LSP servers
		local servers = {
			'lua_ls', 'ts_ls', 'gopls', 'pyright', 'ocamllsp',
			'ruff', 'sourcekit', 'bashls', 'rust_analyzer', 'zls', 'clojure_lsp'
		}
		for _, server in ipairs(servers) do
			vim.lsp.enable(server)
		end
	end
}
