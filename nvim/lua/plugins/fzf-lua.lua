return {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- calling `setup` is optional for customization
        require("fzf-lua").setup({
            fzf_opts = {
                --['--history'] =  vim.fn.stdpath("data") .. '/fzf-lua-history',
            },
            -- required to render icons correctly with kitty
            file_icon_padding = ' ',
        })
    end
}
