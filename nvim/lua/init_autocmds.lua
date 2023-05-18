-- general commands
--
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

vim.api.nvim_create_augroup("CommandLine", {clear=true})
vim.api.nvim_create_autocmd({"CmdlineLeave"}, {
	group = "CommandLine",
	pattern = {"*"},
	callback = function(ev)
		vim.defer_fn( function()vim.cmd('echom ""') end, 3000)
	end,
})


-- language specific commands
--
vim.api.nvim_create_augroup("GoGroup", {clear=true})
vim.api.nvim_create_autocmd({"BufWritePre"}, {
    group = "GoGroup",
    pattern = {"*.go"},
    callback = function(ev)
        vim.api.nvim_command("silent! lua require('vim.lsp.buf').format(nil, 10000)")
        vim.api.nvim_command("silent! lua require('vim.lsp.buf').code_action({ context = { only = { 'source.organizeImports' } }, apply = true})")
    end,
})


