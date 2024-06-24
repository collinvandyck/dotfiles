vim.cmd([[
    augroup LuaFileType
        autocmd!
        autocmd BufRead,BufNewFile *.lua set filetype=lua syntax=lua
    augroup END
]])
