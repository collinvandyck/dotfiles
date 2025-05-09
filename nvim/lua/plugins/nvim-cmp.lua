return {
	"hrsh7th/nvim-cmp",
	name = "cmp",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp-document-symbol",
		"hrsh7th/cmp-nvim-lsp-signature-help",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"nvim-treesitter/nvim-treesitter",
		"zbirenbaum/copilot-cmp",
	},
	config = function()
		local cmp = require('cmp')
		local luasnip = require("luasnip")
		local has_words_before = function()
			unpack = unpack or table.unpack
			local line, col = unpack(vim.api.nvim_win_get_cursor(0))
			return col ~= 0 and
				vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
		end
		cmp.setup({
			performance = {
				debounce = 250, -- 250ms debounce for completion
			},
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
				{ name = 'nvim_lsp' },
				{ name = 'copilot' },
			}, {
				{ name = 'luasnip' },
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
}
