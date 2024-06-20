-- :lua vim.cmd.Hello()
-- :Hello
vim.api.nvim_create_user_command('Hello', function()
    vim.notify("Hello")
end, {});

vim.api.nvim_create_user_command('ProfileStart', function()
    vim.cmd([[
		profile start /tmp/neovim-profile.log
		profile func *
		profile file *
	]])
    vim.notify("started profiling")
end, {});

vim.api.nvim_create_user_command('ProfileStop', function()
    vim.cmd([[
		profile stop
		edit /tmp/neovim-profile.log
	]])
    vim.notify("stopped profiling")
end, {});

vim.api.nvim_create_user_command('Cip', function()
    local result = vim.fn.system('git cip')
    if vim.v.shell_error ~= 0 then
        vim.notify("push failed: " .. result, vim.log.levels.ERROR)
    else
        vim.notify("pushed: " .. result, vim.log.levels.INFO)
    end
end, {})

-- create a fenced code block
--
-- todo: have the command take an input and if it's not supplied, then prompt.
vim.api.nvim_create_user_command('Fcb', function()
    -- Prompt for the syntax
    local syntax = vim.fn.input('Syntax: ')
    -- Lines to be inserted, including the syntax in the first fence
    local lines = { "```" .. syntax, "", "```" }
    -- Current cursor position
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    -- Insert the lines at the current cursor position
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
    -- Move the cursor to the middle of the block
    vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
end, {})


--- These were lifted from:
--- https://www.reddit.com/r/neovim/comments/1dfvluw/share_your_favorite_settingsfeaturesexcerpts_from/

-- Copy text to clipboard using codeblock format ```{ft}{content}```
vim.api.nvim_create_user_command('CopyCodeBlock', function(opts)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, true)
    local content = table.concat(lines, '\n')
    local result = string.format('```%s\n%s\n```', vim.bo.filetype, content)
    vim.fn.setreg('+', result)
    vim.notify 'Text copied to clipboard'
end, { range = true })
