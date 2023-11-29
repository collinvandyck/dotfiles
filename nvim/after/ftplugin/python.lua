vim.api.nvim_buf_set_keymap(0, 'n', vim.g.maplocalleader .. 'c', 'I#<esc>', {noremap = true, silent = true})

vim.bo.autoindent = true
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.smartindent = true
vim.bo.tabstop = 2

