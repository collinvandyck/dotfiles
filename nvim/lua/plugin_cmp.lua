local cmp = require'cmp'

vim.opt.completeopt = 'menu,menuone,noselect,noinsert'

local lsp_symbols = {
	Text =          "   (Text) ",
	Method =        "   (Method)",
	Function =      "   (Function)",
	Constructor =   "   (Constructor)",
	Field =         " ﴲ  (Field)",
	Variable =      "[] (Variable)",
	Class =         "   (Class)",
	Interface =     " ﰮ  (Interface)",
	Module =        "   (Module)",
	Property =      " 襁 (Property)",
	Unit =          "   (Unit)",
	Value =         "   (Value)",
	Enum =          " 練 (Enum)",
	Keyword =       "   (Keyword)",
	Snippet =       "   (Snippet)",
	Color =         "   (Color)",
	File =          "   (File)",
	Reference =     "   (Reference)",
	Folder =        "   (Folder)",
	EnumMember =    "   (EnumMember)",
	Constant =      " ﲀ  (Constant)",
	Struct =        " ﳤ  (Struct)",
	Event =         "   (Event)",
	Operator =      "   (Operator)",
	TypeParameter = "   (TypeParameter)",
}

cmp.setup({
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
	view = {
		entries = "native", -- can be "custom", "wildmenu" or "native"
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	formatting = {
		format = function(entry, item)
			item.kind = lsp_symbols[item.kind]
			item.menu = ({
				buffer = "[Buffer]",
				nvim_lsp = "[LSP]",
				luasnip = "[Snippet]",
				neorg = "[Neorg]",
			})[entry.source.name]
			return item
		end,
	},
	mapping = {
		["<C-n>"] = cmp.mapping.select_next_item(),
		["<C-p>"] = cmp.mapping.select_prev_item(),
		['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
		['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
		['<C-Space>'] = cmp.mapping(cmp.mapping.complete({}), { 'i', 'c' }),
		['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
		['<C-e>'] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
		['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	},
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' }, 
		--{ name = 'buffer' },
	}),
	enabled = function()
		if require"cmp.config.context".in_treesitter_capture("comment")==true or require"cmp.config.context".in_syntax_group("Comment") then
			return false
		else
			return true
		end
	end
})

local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local handlers = require('nvim-autopairs.completion.handlers')

cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done({
    filetypes = {
      -- "*" is a alias to all filetypes
      ["*"] = {
        ["("] = {
          kind = {
            cmp.lsp.CompletionItemKind.Function,
            cmp.lsp.CompletionItemKind.Method,
          },
          handler = handlers["*"]
        }
      },
      lua = {
        ["("] = {
          kind = {
            cmp.lsp.CompletionItemKind.Function,
            cmp.lsp.CompletionItemKind.Method
          },
          ---@param char string
          ---@param item table item completion
          ---@param bufnr number buffer number
          ---@param rules table
          ---@param commit_character table<string>
          handler = function(char, item, bufnr, rules, commit_character)
            -- Your handler function. Inpect with print(vim.inspect{char, item, bufnr, rules, commit_character})
          end
        }
      },
      -- Disable for tex
      tex = false
    }
  })
)
