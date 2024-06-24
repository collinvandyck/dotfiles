vim.cmd([[
    augroup YamlFileType
        autocmd!
        autocmd BufRead,BufNewFile *.yaml set filetype=yaml syntax=yaml
    augroup END
]])
