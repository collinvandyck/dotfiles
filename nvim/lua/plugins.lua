local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.config/nvim/plugged')

-- plugin_treesitter
Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate'})

-- plugin_fzf
Plug('junegunn/fzf', { ['do'] = function() vim.call('fzf#install') end })
Plug('junegunn/fzf.vim')

-- plugin_telescope
Plug('nvim-telescope/telescope.nvim', { ['branch'] = '0.1.x'  } )
Plug('nvim-lua/plenary.nvim')

-- plugin_lspconfig -- requires telescope
Plug('neovim/nvim-lspconfig')

-- plugin_cmp
Plug('hrsh7th/cmp-nvim-lsp')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-cmdline')
Plug('hrsh7th/nvim-cmp')

-- plugin_luasnip
Plug('L3MON4D3/LuaSnip', { ['tag'] = 'v1.*', ['do'] = 'make install_jsregexp'})
Plug('saadparwaiz1/cmp_luasnip')

-- plugin_session
Plug('xolox/vim-misc')
Plug('xolox/vim-session')

-- plugin_autoclose
Plug('m4xshen/autoclose.nvim')

-- plugin_toggleterm
Plug('akinsho/toggleterm.nvim')

-- plugin_nvimtree
Plug('kyazdani42/nvim-web-devicons')
Plug('kyazdani42/nvim-tree.lua')

-- plugin_project
Plug('ahmedkhalf/project.nvim')

-- plugin_trouble
Plug('nvim-tree/nvim-web-devicons')
Plug('folke/trouble.nvim')

-- plugins without init scripts
Plug('tpope/vim-fugitive')            -- git integration
Plug('tpope/vim-rhubarb')             -- git integration with github 
Plug('morhetz/gruvbox') 			  -- gruvbox theme
Plug('jamespwilliams/bat.vim')        -- bat theme
Plug('LnL7/vim-nix')                  -- syntax highlighting for nix files
Plug('rafamadriz/friendly-snippets')  -- commonly useful snippets
Plug('djoshea/vim-autoread')          -- automatically reload files when they change on disk
Plug('github/copilot.vim')            -- copilot integration
-- plugins that i am not sure what they are for

-- plugins that I am going to stop using
-- Plug('sebdah/vim-delve')
-- Plug('easymotion/vim-easymotion')
-- Plug('ray-x/lsp_signature.nvim')      -- show function signature

vim.call('plug#end')

require("plugin_treesitter")
require("plugin_fzf")
require("plugin_lspconfig")
require("plugin_telescope")
require("plugin_cmp")
require("plugin_luasnip")
require("plugin_sessions")
require("plugin_autoclose")
require("plugin_toggleterm")
require("plugin_nvimtree")
require("plugin_project")
require("plugin_gruvbox")
require("plugin_trouble")


