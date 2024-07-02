local group = vim.api.nvim_create_augroup("StandardAutoCommands", { clear = true })

-- if while closing a buffer we only have one normal buffer left, close
-- nvim-tree so that the tab is destroyed.
vim.api.nvim_create_autocmd({ "QuitPre" }, {
	group = group,
	pattern = { "*" },
	callback = function()
		if vim.bo.filetype == 'fugitiveblame' then
			-- don't do anything if we're closing a blame buffer
			return
		end
		local tab = vim.api.nvim_get_current_tabpage()
		local wins = vim.api.nvim_tabpage_list_wins(tab)
		local normals = 0
		local nvim_tree_win = nil
		for _, win in ipairs(wins) do
			local buf = vim.api.nvim_win_get_buf(win);
			local ft = vim.api.nvim_buf_get_option(buf, 'filetype');
			local bt = vim.api.nvim_buf_get_option(buf, 'buftype');
			if ft == 'NvimTree' then
				nvim_tree_win = win
			elseif bt == "" then
				normals = normals + 1
			end
		end
		if nvim_tree_win and normals == 1 then
			vim.api.nvim_win_close(nvim_tree_win, false)
		end
	end,
})

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- after a fugitiveblame buffer is unloaded, resize. the delay works around the
-- lack of a precise event to do this.
vim.api.nvim_create_autocmd("BufUnload", {
	group = group,
	pattern = "*",
	callback = function()
		if vim.bo.filetype == "fugitiveblame" then
			vim.defer_fn(function()
				vim.cmd('wincmd =')
			end, 10)
		end
	end,
})
