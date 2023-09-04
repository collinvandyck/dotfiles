local lsp_util = require "lspconfig/util"
local telescope = require 'telescope.builtin'
local trouble = require 'trouble.providers.telescope'

local custom_attach = function(client, bufnr)
	-- common buffer opts
	local bufopts = { noremap=true, silent=true, buffer=bufnr }

	-- override the lsp request so that we notify on error
	local req = client.request
	client.request = function(method, params, handler, bufnr, config_or_callback)
		local newConfig = {
			timeout = 10000,
			on_error = function(err, method, params, client_id)
				vim.notify("Error on request", err, method, params, client_id)
			end
		}
		return req(method, params, handler, bufnr, newConfig)
	end

	local show_help = function(ev)
		vim.diagnostic.open_float(nil, {focus=false})
	end

	vim.api.nvim_create_autocmd({"BufWritePre"}, {
		buffer = bufnr,
		callback = function(ev)
			vim.api.nvim_command("silent! lua require('vim.lsp.buf').format(nil, 10000)")
			vim.api.nvim_command("silent! lua require('vim.lsp.buf').code_action({ context = { only = { 'source.organizeImports' } }, apply = true})")
		end,
	})

	vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
		buffer = bufnr,
		callback = function(ev)
			vim.api.nvim_command("silent! lua require('vim.lsp.buf').document_highlight()")
		end,
	})
	vim.api.nvim_create_autocmd({"CursorMoved"}, {
		buffer = bufnr,
		callback = function(ev)
			vim.api.nvim_command("silent! lua require('vim.lsp.buf').clear_references()")
		end,
	})

	-- set keymaps
	vim.keymap.set('n','gD',         vim.lsp.buf.declaration, bufopts)
	vim.keymap.set('n','K' ,         vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n','gt',         vim.lsp.buf.type_definition, bufopts)
	vim.keymap.set('n','gd',         '<cmd>Trouble lsp_definitions<CR>', bufopts)
	vim.keymap.set('n','gr',         '<cmd>Trouble lsp_references<CR>', bufopts)
	vim.keymap.set('n','gs',         telescope.lsp_document_symbols, bufopts)
	vim.keymap.set('n','gS',         telescope.lsp_workspace_symbols, bufopts)
	vim.keymap.set('n','gi',         '<cmd>Trouble lsp_implementations<CR>', bufopts)
	vim.keymap.set('n','gI',         telescope.lsp_incoming_calls, bufopts)
	vim.keymap.set('n','gO',         telescope.lsp_outgoing_calls, bufopts)
	vim.keymap.set('n','gh',         show_help, bufopts)
	vim.keymap.set('n','g]',         vim.diagnostic.goto_next, bufopts)
	vim.keymap.set('n','g[',         vim.diagnostic.goto_prev, bufopts)
	vim.keymap.set('n','<leader>gw', vim.lsp.buf.document_symbol, bufopts)
	vim.keymap.set('n','<leader>gW', vim.lsp.buf.workspace_symbol, bufopts)
	vim.keymap.set('n','<leader>ah', vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n','<leader>af', vim.lsp.buf.code_action, bufopts)
	vim.keymap.set('n','<leader>ar', vim.lsp.buf.rename, bufopts)
	-- vim.keymap.set('n','<leader>aF', vim.lsp.buf.formatting, bufopts)
	vim.keymap.set('n','<leader>ai', vim.lsp.buf.incoming_calls, bufopts)
	vim.keymap.set('n','<leader>ao', vim.lsp.buf.outgoing_calls, bufopts)
	-- vim.keymap.set('n','<leader>lw', vim.lsp.buf.list_workspace_folders, bufopts)
end

-- cross plugin dependency
local capabilities = require('cmp_nvim_lsp').default_capabilities()

require'lspconfig'.gopls.setup {
	capabilities = capabilities,
	on_attach = custom_attach,
	cmd = {"gopls", "serve"},
	root_dir = lsp_util.root_pattern("go.work", "go.mod", ".git"),
	settings = {
		semanticTokens = true,
		usePlaceholders = false,
	},
}

require'lspconfig'.tsserver.setup{
	capabilities = capabilities,
	on_attach = custom_attach,
}

require'lspconfig'.rust_analyzer.setup{
	capabilities = capabilities,
	on_attach = custom_attach,
	settings = {
		['rust-analyzer'] = {
			inlay_hints = { enabled = true },
			diagnostics = {
				enable = true;
			}
		}
	}
}

-- require'lspconfig'.pyright.setup{}

