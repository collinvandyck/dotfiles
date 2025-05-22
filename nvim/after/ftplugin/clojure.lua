-- Clojure-specific settings
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.expandtab = true

-- Enable rainbow parentheses for better Lisp readability
vim.cmd([[highlight Delimiter1 guifg=#ff79c6]])
vim.cmd([[highlight Delimiter2 guifg=#8be9fd]])
vim.cmd([[highlight Delimiter3 guifg=#50fa7b]])

-- Clojure-specific keybindings
local opts = { noremap = true, silent = true, buffer = true }

-- Conjure keybindings (using localleader = comma)
-- Main evaluation commands:
-- ,ee - Evaluate current form
-- ,er - Evaluate root form
-- ,eb - Evaluate buffer
-- ,ef - Evaluate file
-- ,lg - Open log buffer
-- ,lh - Toggle log HUD
-- ,ls - Clear log buffer

-- Additional useful bindings for babashka
vim.keymap.set('n', '<localleader>bb', function()
	-- Start babashka nREPL server in background
	vim.fn.jobstart('bb nrepl-server', { detach = true, cwd = vim.fn.getcwd() })
	vim.notify("Starting babashka nREPL server...")
	-- Wait a moment then connect
	vim.defer_fn(function()
		vim.cmd('ConjureConnect')
	end, 2000)
end, opts)

-- Quick start nREPL server with port file
vim.keymap.set('n', '<localleader>ns', function()
	-- Start babashka nREPL and capture the output to get the port
	vim.fn.jobstart('bb nrepl-server --port 1667', { 
		detach = true, 
		cwd = vim.fn.getcwd(),
		on_stdout = function()
			-- Create .nrepl-port file
			vim.fn.writefile({"1667"}, vim.fn.getcwd() .. "/.nrepl-port")
		end
	})
	vim.notify("Starting babashka nREPL server on port 1667...")
end, opts)