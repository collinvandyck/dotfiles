require("luasnip/loaders/from_vscode").load({ include = { "go" } })

-- press <Tab> to expand or jump in a snippet.
vim.api.nvim_set_keymap('i', '<Tab>', 'pumvisible() ? "\\<C-n>" : luasnip#expand_or_jumpable() ? "\\<Plug>luasnip-expand-or-jump" : "\\<Tab>"', {expr = true, silent = true})
vim.api.nvim_set_keymap('i', '<S-Tab>', '<cmd>lua require("luasnip").jump(-1)<Cr>', {silent = true})
vim.api.nvim_set_keymap('s', '<Tab>', '<cmd>lua require("luasnip").jump(1)<Cr>', {silent = true})
vim.api.nvim_set_keymap('s', '<S-Tab>', '<cmd>lua require("luasnip").jump(-1)<Cr>', {silent = true})

-- For changing choices in choiceNodes (not strictly necessary for a basic setup).
vim.api.nvim_set_keymap('i', '<C-E>', 'luasnip#choice_active() ? "\\<Plug>luasnip-next-choice" : "\\<C-E>"', {expr = true, silent = true})
vim.api.nvim_set_keymap('s', '<C-E>', 'luasnip#choice_active() ? "\\<Plug>luasnip-next-choice" : "\\<C-E>"', {expr = true, silent = true})


