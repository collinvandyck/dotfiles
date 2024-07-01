return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"cmp"
	},
	config = function()
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
					local lspb = require('vim.lsp.buf')
					lspb.format({ nil })
					--lspb.code_action({ context = { only = { 'source.organizeImports' } }, apply = true})
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
			local fzf = require("fzf-lua")
			local jump_opts = { jump_to_single_result = true, sync = false }
			vim.keymap.set('n', 'gD', function() fzf.lsp_declarations(jump_opts) end, bufopts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
			vim.keymap.set('n', 'ga', fzf.lsp_code_actions, bufopts)
			vim.keymap.set('n', 'gt', function() fzf.lsp_typedefs(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gd', function() fzf.lsp_definitions(jump_opts) end, bufopts)
			vim.keymap.set('n', 'gr', function()
				fzf.lsp_references({
					jump_to_single_result = true,
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
		vim.cmd([[
        augroup LspConfigSetColorScheme
            autocmd!
            autocmd! ColorScheme * highlight NormalFloat guifg=white guibg=#1f2335
            autocmd! ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335
        augroup END
        ]])
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
			--if err or not (result and result.contents) then return end
			--local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
			--markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
			--if vim.tbl_isempty(markdown_lines) then return end
			--vim.notify(tostring(markdown_lines))
			--local bufnr, winnr = vim.lsp.util.open_floating_preview(markdown_lines, 'markdown', config)
			--vim.api.nvim_win_set_option(winnr, 'conceallevel', 3)

			vim.lsp.handlers.hover(err, result, ctx, config)
		end
		local handlers = {
			["textDocument/hover"] = vim.lsp.with(hover_handler, {
				border = handlers_border,
				stylize_markdown = false,
				virtual_text = false,
			}),
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
					cargo = {},
					check = {
						extraArgs = {
							"--target-dir",
							"target/rust-analzyer",
						},
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
