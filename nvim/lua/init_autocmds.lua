-- startup commands

vim.cmd([[
  augroup StartupCommands
    autocmd!
    autocmd VimEnter * lua check_empty_and_toggle_tree()
  augroup END
]])

function check_empty_and_toggle_tree()
  local bufnr = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local buf_line_count = vim.api.nvim_buf_line_count(bufnr)

  if buf_name == "" and buf_line_count == 1 then
    vim.cmd("silent! NvimTreeToggle")
    vim.cmd("wincmd l")
  end
end

vim.cmd([[
augroup GoGroup
  autocmd!
  autocmd BufWritePre *.go :silent! lua vim.lsp.buf.format(nil, 10000)
  autocmd BufWritePre *.go lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
augroup END
]])
