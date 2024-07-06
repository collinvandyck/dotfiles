local group = vim.api.nvim_create_augroup("StandardAutoCommands", { clear = true })


-- resize the windows on all tabpages on startup. this addresses an issue where
-- nvim-tree is not restored from the session plugin, and a split will be
-- unsized due to the negative space nvim-tree left behind.
vim.api.nvim_create_autocmd({ "Vimenter" }, {
	group = group,
	pattern = { "*" },
	callback = function()
		local start = vim.api.nvim_get_current_tabpage()
		for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
			vim.api.nvim_set_current_tabpage(tab)
			vim.cmd("wincmd =")
		end
		vim.api.nvim_set_current_tabpage(start)
	end,
})

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

-- sets the wrapping behavior based on the current buffer ft
vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	pattern = "*",
	callback = function()
		local fts = { "markdown" }
		for _, ft in ipairs(fts) do
			if vim.bo.filetype == ft then
				vim.wo.wrap = true
				vim.wo.linebreak = true
				vim.wo.breakindent = true
				return
			end
		end
		vim.wo.wrap = false
		vim.wo.linebreak = false
		vim.wo.breakindent = false
	end,
})
