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

vim.api.nvim_create_user_command('Cip', function()
	local result = vim.fn.system('git cip')
	if vim.v.shell_error ~= 0 then
		vim.notify("push failed: " .. result, vim.log.levels.ERROR)
	else
		vim.notify("pushed: " .. result, vim.log.levels.INFO)
	end
end, {})
