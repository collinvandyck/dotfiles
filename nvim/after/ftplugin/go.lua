vim.bo.expandtab = false
vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
vim.bo.smartindent = true
vim.bo.tabstop = 4

vim.api.nvim_buf_set_keymap(0, 'n', vim.g.maplocalleader .. 'c', 'I//<esc>', {noremap = true, silent = true})

