vim.cmd([[
augroup GoGroup
  autocmd!
  autocmd BufWritePre *.go :silent! lua vim.lsp.buf.formatting_sync(nil, 10000)
  autocmd BufWritePre *.go lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
augroup END
]])
