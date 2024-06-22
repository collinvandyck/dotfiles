return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    init = function()
        require("tokyonight").setup({
            style = "night",
        })
    end,
}
