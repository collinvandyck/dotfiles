local group = vim.api.nvim_create_augroup("LazygitMods", { clear = true })
vim.api.nvim_create_autocmd("TermEnter", {
	pattern = "*",
	group = group,
	callback = function()
		local name = vim.api.nvim_buf_get_name(0)
		if string.find(name, "lazygit") then
			vim.keymap.set("t", "<ESC>",
				function()
					-- Get the terminal job ID for the current buffer
					local bufnr = vim.api.nvim_get_current_buf()
					local chan = vim.b[bufnr].terminal_job_id
					if chan then
						-- Send the ESC key sequence to the terminal
						-- "\x1b" is the escape character
						vim.api.nvim_chan_send(chan, "\x1b")
					end
					--vim.cmd([[call feedkeys("q")]])
				end,
				{ buffer = true })
			return
		end
	end,
})
return {
	"kdheepak/lazygit.nvim",
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	-- optional for floating window border decoration
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	-- setting the keybinding for LazyGit with 'keys' is recommended in
	-- order to load the plugin when the command is run for the first time
	keys = {
		{ "<leader>gg",  "<cmd>LazyGit<cr>",                  desc = "LazyGit" },
		{ "<leader>lgg", "<cmd>LazyGit<cr>",                  desc = "LazyGit" },
		{ "<leader>lgf", "<cmd>LazyGitFilterCurrentFile<cr>", desc = "LazyGit Current File" },
	}
}
