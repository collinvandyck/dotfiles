vim.cmd([[
    augroup SSHConfigFileType
        autocmd!
        autocmd BufRead,BufNewFile **/ssh/config set filetype=sshconfig
    augroup END
]])
