vim.cmd([[
    augroup GitIngoreFileType
        autocmd!
        autocmd BufRead,BufNewFile .gitignore_global set filetype=gitignore
    augroup END
]])
