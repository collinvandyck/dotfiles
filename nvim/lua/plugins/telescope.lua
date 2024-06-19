return {
    "nvim-telescope/telescope.nvim",
    tag = '0.1.5',
    dependencies = {
        "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
        local actions = require("telescope.actions")
        local action_state = require('telescope.actions.state')
        local trouble = require("trouble.sources.telescope")

        require('telescope').setup {
            defaults = {
                layout_strategy = "vertical",
                layout_config = {
                    vertical = {
                        width = 0.95,
                        height = 0.95,
                        preview_width = 0.95,
                    },
                },
                -- todo: need to get ctrl-p/ctrl-n mappings to choose items
                mappings = {
                    i = {
                        ["<esc>"] = actions.close,
                        ["<C-u>"] = false, -- enable clearing prompt
                        ["<C-t>"] = trouble.open,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-p>"] = actions.move_selection_previous,
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-n>"] = actions.move_selection_next,
                    },
                    n = {
                        ["<C-t>"] = trouble.open,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-p>"] = actions.move_selection_previous,
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-n>"] = actions.move_selection_next,
                    },
                }
            },
            pickers = {
                find_files = {},
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown {}
                },
                aerial = {
                    -- Display symbols as <root>.<parent>.<symbol>
                    show_nesting = {
                        ["_"] = false, -- This key will be the default
                        json = true,   -- You can set the option for specific filetypes
                        yaml = true,
                    },
                },
            },
        }
        require("telescope").load_extension("ui-select")
    end
}
