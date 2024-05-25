-- :lua vim.cmd.Hello()
-- :Hello
vim.api.nvim_create_user_command('Hello', function()
	vim.notify("Hello")
end, {});

vim.api.nvim_create_user_command('ProfileStart', function()
	vim.cmd([[
		profile start /tmp/neovim-profile.log
		profile func *
		profile file *
	]])
	vim.notify("started profiling")
end, {});

vim.api.nvim_create_user_command('ProfileStop', function()
	vim.cmd([[
		profile stop
		edit /tmp/neovim-profile.log
	]])
	vim.notify("stopped profiling")
end, {});
