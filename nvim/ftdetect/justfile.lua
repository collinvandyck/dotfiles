vim.filetype.add({
	filename = {
		['justfile'] = 'just',
	},
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "just",
	callback = function()
		vim.opt_local.textwidth = 80
		-- Inherit 'make' settings:
		vim.cmd('runtime! ftplugin/make.vim')
		vim.cmd('runtime! syntax/make.vim')
	end
})
