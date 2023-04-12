local lsp_util = require "lspconfig/util"
local telescope = require 'telescope.builtin'
local trouble = require 'trouble.providers.telescope'

local custom_attach = function(client, bufnr)
	local bufopts = { noremap=true, silent=true, buffer=bufnr }

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


	vim.keymap.set('n','gD',         vim.lsp.buf.declaration, bufopts)
	vim.keymap.set('n','K' ,         vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n','gt',         vim.lsp.buf.type_definition, bufopts)
	vim.keymap.set('n','gd',         telescope.lsp_definitions, bufopts)
	vim.keymap.set('n','gr',         '<cmd>Trouble lsp_references<CR>', bufopts)
	vim.keymap.set('n','gs',         telescope.lsp_document_symbols, bufopts)
	vim.keymap.set('n','gS',         telescope.lsp_workspace_symbols, bufopts)
	vim.keymap.set('n','gi',         '<cmd>Trouble lsp_implementations<CR>', bufopts)
	vim.keymap.set('n','gI',         telescope.lsp_incoming_calls, bufopts)
	vim.keymap.set('n','gD',         telescope.lsp_outgoing_calls, bufopts)
	vim.keymap.set('n','<leader>gw', vim.lsp.buf.document_symbol, bufopts)
	vim.keymap.set('n','<leader>gW', vim.lsp.buf.workspace_symbol, bufopts)
	vim.keymap.set('n','<leader>ah', vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n','<leader>af', vim.lsp.buf.code_action, bufopts)
	vim.keymap.set('n','<leader>ar', vim.lsp.buf.rename, bufopts)
	vim.keymap.set('n','<leader>aF', vim.lsp.buf.formatting, bufopts)
	vim.keymap.set('n','<leader>ai', vim.lsp.buf.incoming_calls, bufopts)
	vim.keymap.set('n','<leader>ao', vim.lsp.buf.outgoing_calls, bufopts)
	-- vim.keymap.set('n','<leader>lw', vim.lsp.buf.list_workspace_folders, bufopts)
end

require'lspconfig'.gopls.setup {
	on_attach = custom_attach,
	cmd = {"gopls", "serve"},
	root_dir = lsp_util.root_pattern("go.work", "go.mod", ".git"),
	settings = {
	},
}

require'lspconfig'.tsserver.setup{
	on_attach = custom_attach,
}

