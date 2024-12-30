vim.bo.textwidth = 99
--vim.keymap.set('i', "'", "'", { buffer = 0 })

local MiniPairs = require('mini.pairs')

-- handle '' but disable for lifetimes
MiniPairs.map_buf(0, 'i', "'", {
	action = 'closeopen',
	pair = "''",
	neigh_pattern = '[^%a\\&<].',
})

-- handle <Generic> types
MiniPairs.map_buf(0, 'i', '<', {
	action = 'open',
	pair = '<>',
	neigh_pattern = '[^ ].',
})
MiniPairs.map_buf(0, 'i', '>', {
	action = 'close',
	pair = '<>',
	neigh_pattern = '[^ ].',
})
