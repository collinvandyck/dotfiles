return {
	"Olical/conjure",
	ft = { "clojure", "clojurescript", "edn" },
	config = function()
		-- Set localleader to comma for easier access
		vim.g.maplocalleader = ","
		
		-- Conjure configuration
		vim.g["conjure#client#clojure#nrepl#eval#auto_require"] = false
		vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false
		vim.g["conjure#log#hud#enabled"] = true
		vim.g["conjure#log#hud#width"] = 0.42
		vim.g["conjure#log#hud#anchor"] = "SE"
		vim.g["conjure#log#botright"] = true
		
		-- Enable babashka support
		vim.g["conjure#filetype#clojure"] = "conjure.client.clojure.nrepl"
	end,
}