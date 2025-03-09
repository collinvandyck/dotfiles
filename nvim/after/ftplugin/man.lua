vim.schedule(function()
	require("aerial").toggle()
	vim.cmd('wincmd p')
end)
