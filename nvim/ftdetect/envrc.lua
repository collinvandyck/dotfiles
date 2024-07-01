vim.cmd([[
    augroup EnvRcFileType
        autocmd!
        autocmd BufRead,BufNewFile *.envrc set filetype=sh syntax=sh
    augroup END
]])
