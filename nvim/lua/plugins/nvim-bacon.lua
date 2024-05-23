return {
	"Canop/nvim-bacon",
	config = function()
		require("bacon").setup({
			quickfix = {
				enabled = false, -- true to populate the quickfix list with bacon errors and warnings
				event_trigger = true, -- triggers the QuickFixCmdPost event after populating the quickfix list
			},
		})
	end,
}
