vim.api.nvim_buf_set_keymap(0, 'n', vim.g.maplocalleader .. 'c', 'I#<esc>', { noremap = true, silent = true })
vim.bo.autoindent = true
vim.bo.shiftwidth = 4
vim.bo.smartindent = true
vim.bo.tabstop = 4
