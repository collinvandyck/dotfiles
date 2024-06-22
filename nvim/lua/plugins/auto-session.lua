return {
    "rmagatti/auto-session",
    enabled = true,
    dependencies = {
    },
    config = function()
        vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
        require("auto-session").setup {
            log_level = vim.log.levels.ERROR,
            auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
            pre_save_cmds = {
                function()
                    -- delete all nvim-tree buffers before saving the
                    -- session
                    local function close_all_nvim_trees()
                        local buf_delete = vim.api.nvim_buf_delete
                        local buf_list = vim.api.nvim_list_bufs()

                        for _, buf in ipairs(buf_list) do
                            local buftype = vim.api.nvim_buf_get_option(buf, "ft")
                            if buftype == "NvimTree" then
                                pcall(buf_delete, buf, {})
                            end
                        end
                    end
                    close_all_nvim_trees()
                end,
            },
            post_restore_cmds = { function()
                --local nt_api = require("nvim-tree.api")
                --nt_api.tree.reload()
            end }
        }
    end,
}
