-- fzf_setup.lua
vim.g.fzf_layout = { window = { width = 1, height = 1 } }
vim.g.fzf_preview_window = { 'right:50%', 'ctrl-/' }
vim.g.fzf_buffers_jump = 1

function _G.RipgrepFzf(query, fullscreen)
    print('RipgrepFzf query:', vim.fn.shellescape(query))
    local command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
    local initial_command = string.format(command_fmt, vim.fn.shellescape(query))
    local reload_command = string.format(command_fmt, '{q}')
    local spec = { options = { '--phony', '--print-query', '--query', query, '--bind', 'change:reload:' .. reload_command } }
    vim.call('fzf#vim#grep', initial_command, 1, vim.call('fzf#vim#with_preview', spec), fullscreen)
end

vim.cmd("command! -nargs=* -bang RG lua RipgrepFzf(<q-args>, <bang>0)")

vim.cmd([[
    command! -bang -nargs=? -complete=dir ConfigFiles
                \ call fzf#vim#files(
                \ '~/ngrok/config',
                \ fzf#vim#with_preview({}),
                \ <bang>0)
]])

vim.cmd([[
    command! -bang -nargs=? -complete=dir GoFiles
                \ call fzf#vim#files(
                \ '~/ngrok/go',
                \ fzf#vim#with_preview({}),
                \ <bang>0)
]])

local function TestFzf(query, fullscreen)
    local command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
    local initial_command = string.format(command_fmt, vim.fn.shellescape(query))
    local reload_command = string.format(command_fmt, '{q}')
    local spec = { options = { '--phony', '--query', query, '--bind', 'change:reload:' .. reload_command } }
    local res = vim.call('fzf#vim#grep', initial_command, 1, vim.call('fzf#vim#with_preview', spec), fullscreen)
    print(res)
    print("done")
    return res
end

vim.cmd("command! -nargs=* -bang TRG lua TestFzf(<q-args>, <bang>0)")

