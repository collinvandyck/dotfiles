return {
    "ahmedkhalf/project.nvim",
    config = function()
        require("project_nvim").setup {
            detection_methods = { "pattern" },

            -- rules applied in order
            patterns = {
                ".git",
            },

            -- for debugging
            silent_chdir = true,
        }
    end
}
