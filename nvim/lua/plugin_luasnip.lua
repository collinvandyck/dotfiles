require("luasnip/loaders/from_lua").load({ paths = {"~/.config/nvim/snippets"} })

local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
keymap("i", "<m-j>", "<cmd>lua require('luasnip').jump(1)<CR>", { silent = true, noremap = true})
keymap("i", "<m-k>", "<cmd>lua require('luasnip').jump(-1)<CR>", { silent = true, noremap = true})
keymap("s", "<m-j>", "<cmd>lua require('luasnip').jump(1)<CR>", { silent = true, noremap = true})
keymap("s", "<m-k>", "<cmd>lua require('luasnip').jump(-1)<CR>", { silent = true, noremap = true})

