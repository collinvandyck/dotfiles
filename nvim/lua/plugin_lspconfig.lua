local lsp_util = require "lspconfig/util"
local telescope = require 'telescope.builtin'
local trouble = require 'trouble.providers.telescope'
local custom_attach = function(client, bufnr)
	local bufopts = { noremap=true, silent=true, buffer=bufnr }
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
	vim.keymap.set('n','gD',         vim.lsp.buf.declaration, bufopts)
	vim.keymap.set('n','K' ,         vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n','ga',         vim.lsp.buf.code_action, bufopts)
	vim.keymap.set('n','gt',         vim.lsp.buf.type_definition, bufopts)
	vim.keymap.set('n','gd',         '<cmd>Telescope lsp_definitions<CR>', bufopts)
	vim.keymap.set('n','gr',         '<cmd>Trouble lsp_references<CR>', bufopts)
	vim.keymap.set('n','gs',         telescope.lsp_document_symbols, bufopts)
	vim.keymap.set('n','gS',         telescope.lsp_workspace_symbols, bufopts)
	vim.keymap.set('n','gi',         '<cmd>Telescope lsp_implementations<CR>', bufopts)
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
	vim.keymap.set('n','<leader>ai', vim.lsp.buf.incoming_calls, bufopts)
	vim.keymap.set('n','<leader>ao', vim.lsp.buf.outgoing_calls, bufopts)
	-- vim.keymap.set('n','<leader>aF', vim.lsp.buf.formatting, bufopts)
	-- vim.keymap.set('n','<leader>lw', vim.lsp.buf.list_workspace_folders, bufopts)
end

vim.cmd [[autocmd! ColorScheme * highlight NormalFloat guibg=#1f2335]]
vim.cmd [[autocmd! ColorScheme * highlight FloatBorder guifg=white guibg=#1f2335]]

local border = {
      {"🭽", "FloatBorder"},
      {"▔", "FloatBorder"},
      {"🭾", "FloatBorder"},
      {"▕", "FloatBorder"},
      {"🭿", "FloatBorder"},
      {"▁", "FloatBorder"},
      {"🭼", "FloatBorder"},
      {"▏", "FloatBorder"},
}
local handlers =  {
  ["textDocument/hover"] =  vim.lsp.with(vim.lsp.handlers.hover, {border = border}),
  ["textDocument/signatureHelp"] =  vim.lsp.with(vim.lsp.handlers.signature_help, {border = border }),
}

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
	handlers = handlers,
	capabilities = capabilities,
	on_attach = custom_attach,
	on_init = function(client) 
		-- setup defaults
		local cargo = { }
		local check = {
			extraArgs = { 
				"--target-dir", 
				"target/rust-analyzer",
			},
		}
		local rustfmt = {
			extraArgs = { "+nightly" },
		}
		local diagnostics = {
			enable = true,
		}
		local inlay_hints = { 
			enabled = true,
		}
		-- override based on RA_TARGET
		-- RA_TARGET=x86_64-pc-windows-msvc neovim
		local ra_target = os.getenv("RA_TARGET")
		if ra_target then
			cargo.target = ra_target
			table.insert(check.extraArgs, "--target")
			table.insert(check.extraArgs, ra_target)
		end
		-- build the final settings table and set on client config
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
		-- Send the didChangeConfiguration notification
        client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
	end,
}

-- require'lspconfig'.pyright.setup{}

