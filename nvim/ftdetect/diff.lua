vim.cmd([[
    augroup DiffFileType
        autocmd!
        autocmd BufRead,BufNewFile **/COMMIT_EDITMSG set filetype=diff syntax=diff
    augroup END
]])
