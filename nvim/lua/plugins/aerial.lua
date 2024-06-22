return {
    'stevearc/aerial.nvim',
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        require("aerial").setup({
            layout = {
                default_direction = "right",
                --placement = "edge",
            },
            attach_mode = "global",
            highlight_on_jump = false,
            filter_kind = {
                ['_'] = {
                    "Class",
                    "Constructor",
                    "Enum",
                    "Function",
                    "Interface",
                    "Module",
                    "Method",
                    "Struct",
                }
            },
        })
    end
}
