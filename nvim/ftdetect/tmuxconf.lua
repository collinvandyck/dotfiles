vim.cmd([[
    augroup TmuxConfFileType
        autocmd!
        autocmd BufRead,BufNewFile tmux.conf set filetype=tmux
    augroup END
]])
