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

-- This is an example of how to use fzf-lua to show some options, and then take
-- action based on the one selected.
vim.api.nvim_create_user_command('TestFzf', function(opts)
    local commands = {
        { name = "Show Date",   action = function() print(os.date()) end },
        { name = "Hello World", action = function() print("Hello, world!") end },
        -- Add more commands and their actions here
    }
    -- Convert the list of commands to a format suitable for fzf, which is a list of strings
    local cmd_list = {}
    for i, cmd in ipairs(commands) do
        table.insert(cmd_list, cmd.name)
    end
    -- Use fzf_exec to display the commands. When a command is selected, execute its associated action.
    require 'fzf-lua'.fzf_exec(cmd_list, {
        -- Customize the prompt (optional)
        prompt = 'Commands> ',
        -- Define what happens when an item is selected
        actions = {
            ['default'] = function(selected)
                for _, cmd in ipairs(commands) do
                    if cmd.name == selected[1] then
                        cmd.action()
                        break
                    end
                end
            end
        }
    })
end, {})

-- creates a new temporary doc and persists it into /tmp. ft=md.
vim.api.nvim_create_user_command('Tmp', function()
    vim.fn.system('mkdir -p /tmp/scratch/')
    local fileName = "/tmp/scratch/scratch-" .. os.time() .. ".md"
    local file = io.open(fileName, "w")
    if file then
        file:close()
    end
    vim.cmd('edit ' .. fileName)
    vim.bo.textwidth = 0
    vim.wo.wrap = true
    vim.wo.linebreak = false

    -- on quit from a scratch doc, write the file, and copy it to the clipboard
    -- before exiting.
    --
    -- todo: have this be an autocmd for this particular buffer.
    vim.keymap.set('n', 'quitcopy', function()
        vim.cmd('w')
        local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        vim.fn.setreg('+', content)
        vim.cmd('qa')
    end, { noremap = true, buffer = true })
end, {})
