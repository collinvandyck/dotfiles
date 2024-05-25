-- Note: use :Inspect to find the highlight groups for a particular code block.
vim.cmd('colorscheme tokyonight-night')
vim.cmd [[highlight Comment guisp=#8a8a8a guifg=#8a8a8a]]
vim.cmd [[highlight DiagnosticUnderlineHint gui=undercurl guisp=#8a8a8a guifg=#8a8a8a]]
vim.cmd [[highlight DiagnosticUnnecessary gui=undercurl guisp=#8a8a8a guifg=#8a8a8a]]
vim.cmd [[highlight TabLine guisp=#8a8a8a guifg=#8a8a8a]]
vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
