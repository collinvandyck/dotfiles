-- general commands

-- VimEnter: when we enter vim for the first time.
vim.api.nvim_create_augroup("Startup", {clear=true})
vim.api.nvim_create_autocmd({"VimEnter"}, {
	group = "Startup",
	pattern = {"*"},
	callback = function(ev)
		local bufnr = vim.api.nvim_get_current_buf()
		local buf_name = vim.api.nvim_buf_get_name(bufnr)
		local buf_line_count = vim.api.nvim_buf_line_count(bufnr)

		if buf_name == "" and buf_line_count == 1 then
			vim.cmd("silent! NvimTreeToggle")
			vim.cmd("wincmd l")
		end
	end,
})

-- TabNew
-- Always toggle nvimtree when creating a new tab
vim.api.nvim_create_augroup("TabNew", {clear=true})
vim.api.nvim_create_autocmd({"TabNew"}, {
	group = "TabNew",
	pattern = {"*"},
	callback = function(ev)
		vim.cmd("silent! NvimTreeToggle")
	end,
})



vim.api.nvim_create_augroup("CommandLine", {clear=true})
vim.api.nvim_create_autocmd({"CmdlineLeave"}, {
	group = "CommandLine",
	pattern = {"*"},
	callback = function(ev)
		vim.defer_fn( function()vim.cmd('echom ""') end, 3000)
	end,
})


