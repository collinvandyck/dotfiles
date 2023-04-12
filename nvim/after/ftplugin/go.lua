vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"

vim.api.nvim_buf_set_keymap(0, 'n', vim.g.maplocalleader .. 'c', 'I//<esc>', {noremap = true, silent = true})

