return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")
		ts.setup({})

		ts.install({ "regex", "nu" })

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local buf = args.buf
				local ft = vim.bo[buf].filetype
				local lang = vim.treesitter.language.get_lang(ft) or ft
				if not lang or lang == "" then
					return
				end

				local ok = pcall(vim.treesitter.start, buf, lang)
				if not ok and vim.tbl_contains(ts.get_available(), lang) then
					ts.install(lang)
				end
			end,
		})

		local node_stacks = {}
		vim.api.nvim_create_autocmd({ "TextChanged", "BufDelete", "BufWipeout" }, {
			callback = function(args)
				node_stacks[args.buf] = nil
			end,
		})

		local function select_node(node)
			local srow, scol, erow, ecol = node:range()
			local end_row, end_col
			if ecol == 0 and erow > 0 then
				local line = vim.api.nvim_buf_get_lines(0, erow - 1, erow, false)[1] or ""
				end_row, end_col = erow - 1, math.max(0, #line - 1)
			else
				end_row, end_col = erow, math.max(0, ecol - 1)
			end

			if vim.api.nvim_get_mode().mode ~= "n" then
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
					"nx",
					false
				)
			end
			vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
			vim.cmd("normal! v")
			vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
		end

		local function init_selection()
			local buf = vim.api.nvim_get_current_buf()
			local ok_parser, parser = pcall(vim.treesitter.get_parser, buf)
			if not ok_parser or not parser then
				return
			end
			parser:parse()
			local node = vim.treesitter.get_node()
			if not node then
				return
			end
			node_stacks[buf] = { node }
			select_node(node)
		end

		local function expand(scope)
			local buf = vim.api.nvim_get_current_buf()
			local stack = node_stacks[buf]
			if not stack or #stack == 0 then
				return init_selection()
			end
			local target = stack[#stack]:parent()
			if scope then
				while target do
					local sr, _, er, _ = target:range()
					if target:named() and er > sr then
						break
					end
					target = target:parent()
				end
			end
			if not target then
				return
			end
			table.insert(stack, target)
			select_node(target)
		end

		local function shrink()
			local buf = vim.api.nvim_get_current_buf()
			local stack = node_stacks[buf]
			if not stack or #stack <= 1 then
				return
			end
			table.remove(stack)
			select_node(stack[#stack])
		end

		vim.keymap.set("n", "gnn", init_selection, { silent = true, desc = "TS: init incremental select" })
		vim.keymap.set("x", "=", function() expand(false) end, { silent = true, desc = "TS: expand to parent" })
		vim.keymap.set("x", "+", function() expand(true) end, { silent = true, desc = "TS: expand to scope" })
		vim.keymap.set("x", "-", shrink, { silent = true, desc = "TS: shrink selection" })
	end,
}
