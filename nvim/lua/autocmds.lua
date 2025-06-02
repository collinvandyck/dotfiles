local group = vim.api.nvim_create_augroup("StandardAutoCommands", { clear = true })


--vim.api.nvim_create_autocmd({ "FileType" }, {
--group = group,
--pattern = { "man" },
--callback = function()
--local win = vim.api.nvim_get_current_win()
--local buf = vim.api.nvim_win_get_buf(win)
--vim.schedule(function()
--local buf2 = vim.api.nvim_win_get_buf(win)
--local redraw = buf == buf2
--require("aerial").open()
--if redraw then
--vim.cmd('wincmd p')
--vim.wo.wrap = false
--end
--end)
--end
--})

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

-- ensure nvim-tree tracking works with Go files
vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	pattern = "*.go",
	callback = function()
		-- Force nvim-tree to update focused file if visible
		if require("nvim-tree.view").is_visible() then
			vim.schedule(function()
				require("nvim-tree.api").tree.find_file()
			end)
		end
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

-- flash nvim background when gaining focus (similar to tmux pane flash)
vim.api.nvim_create_autocmd("FocusGained", {
	group = group,
	pattern = "*",
	callback = function()
		-- Store original background
		local original_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
		
		-- Set flash background (black)
		vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
		vim.cmd("redraw")
		
		-- Restore original background after delay
		vim.defer_fn(function()
			if original_bg then
				vim.api.nvim_set_hl(0, "Normal", { bg = original_bg })
			else
				vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
			end
			vim.cmd("redraw")
		end, 50)
	end,
})

-- trims trailing spaces before writing text files
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	pattern = "*",
	callback = function()
		-- strip trailing spaces from the end of the line
		local current_view = vim.fn.winsaveview()
		vim.cmd([[keeppatterns %s/\s\+$//e]])
		vim.fn.winrestview(current_view)

		-- delete any trailing blank lines
		local last = vim.fn.prevnonblank(vim.fn.line("$"))
		if last < vim.fn.line("$") - 1 then
			vim.api.nvim_buf_set_lines(0, last, -2, false, {})
		end
	end,
})
