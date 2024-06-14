-- if while closing a buffer we only have one normal buffer left, close
-- nvim-tree so that the tab is destroyed.
vim.api.nvim_create_augroup("QuitHooks", { clear = true })
vim.api.nvim_create_autocmd({ "QuitPre" }, {
    group = "QuitHooks",
    pattern = { "*" },
    callback = function()
        if vim.bo.filetype == 'fugitiveblame' then
            -- don't do anything if we're closing a blame buffer
            return
        end
        local tab = vim.api.nvim_get_current_tabpage()
        local wins = vim.api.nvim_tabpage_list_wins(tab)
        local normals = 0
        local nvim_tree_win = nil
        for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win);
            local ft = vim.api.nvim_buf_get_option(buf, 'filetype');
            local bt = vim.api.nvim_buf_get_option(buf, 'buftype');
            if ft == 'NvimTree' then
                nvim_tree_win = win
            elseif bt == "" then
                normals = normals + 1
            end
        end
        if nvim_tree_win and normals == 1 then
            vim.api.nvim_win_close(nvim_tree_win, false)
        end
    end,
})

-- once lsp progress has finished, clear the fidget notification.
-- https://github.com/j-hui/fidget.nvim/issues/229
vim.api.nvim_create_autocmd("LspProgress", {
    pattern = "end",
    callback = function(ev)
        local token = ev.data.params.token
        local client_id = ev.data.client_id
        local client = client_id and vim.lsp.get_client_by_id(client_id)
        if client and token then
            require("fidget").notification.remove(client.name, token)
        end
    end,
})
