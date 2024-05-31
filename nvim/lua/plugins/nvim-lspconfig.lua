return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"cmp"
	},
	config = function()
		local lsp_util = require "lspconfig/util"
		local telescope = require 'telescope.builtin'
		-- local trouble = require 'trouble.providers.telescope'
		local custom_attach = function(client, bufnr)
			local bufopts = { noremap = true, silent = true, buffer = bufnr }
			local show_help = function()
				vim.diagnostic.open_float(nil, { focus = false })
			end
			vim.api.nvim_create_autocmd({ "BufWritePre" }, {
				buffer = bufnr,
				callback = function()
					require('vim.lsp.buf').format({ nil })
					--[[
						vim.api.nvim_command(
							"silent! lua require('vim.lsp.buf').code_action({ context = { only = { 'source.organizeImports' } }, apply = true})")
						--]]
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
			vim.keymap.set('n', 'gr', telescope.lsp_references, bufopts)
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
		local function hover_handler(err, result, ctx, config)
			vim.lsp.handlers.hover(err, result, ctx, config)
		end
		local handlers = {
			["textDocument/hover"] = vim.lsp.with(hover_handler, { border = handlers_border }),
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
		require("lspconfig").pyright.setup({
			capabilities = capabilities,
			handlers = handlers,
			on_attach = custom_attach,
		})
		require("lspconfig").rust_analyzer.setup({
			capabilities = capabilities,
			handlers = handlers,
			on_attach = custom_attach,
			settings = (function()
				local ra_settings = {
					cargo = {
						allFeatures = true,
					},
					check = {
						extraArgs = {
							"--target-dir",
							"target/rust-analzyer",
						},
					},
					checkOnSave = {
						--enable = false,
						--command = 'clippy',
					},
					inlayHints = {
						locationLinks = false
					},
					diagnostics = {
						enable = true,
						experimental = {
							enable = false,
						},
					},
					rustfmt = {
						extraArgs = {
							"+nightly-2024-03-29",
						},
					},
				}

				-- RA_TARGET=x86_64-pc-windows-gnu neovim
				local ra_target = os.getenv("RA_TARGET")
				if ra_target then
					require("notify")(ra_target)
					ra_settings.cargo.target = ra_target
					table.insert(ra_settings.check.extraArgs, "--target")
					table.insert(ra_settings.check.extraArgs, ra_target)
				end

				local settings = {
					['rust-analyzer'] = ra_settings,
				}
				--print(vim.inspect(settings));
				return settings
			end)(),
		})
	end
}
