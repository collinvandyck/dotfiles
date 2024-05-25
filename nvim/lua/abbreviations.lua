local abbreviations = {
	{ "adn",    "and" },
	{ "waht",   "what" },
	{ "tehn",   "then" },
	{ "reutrn", "return" },
	{ "reutnr", "return" },
}
for _, tuple in ipairs(abbreviations) do
	local from, to = unpack(tuple)
	vim.api.nvim_command('iabbrev ' .. from .. ' ' .. to)
end
