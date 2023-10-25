-- note that you have to enable clipboard access in iterm2 to get this to work.
--
require('osc52').setup {
  max_length = 0,      -- Maximum length of selection (0 for no limit)
  silent     = false,  -- Disable message on successful copy
  trim       = false,  -- Trim surrounding whitespaces before copy
}

-- not used, copied from examples.
function copy_plus()
  if vim.v.event.operator == 'y' and vim.v.event.regname == '+' then
    require('osc52').copy_register('+')
  end
end

function copy()
  if vim.v.event.operator == 'y' then
    require('osc52').copy_register(vim.v.event.regname)
  end
end

vim.api.nvim_create_autocmd('TextYankPost', {callback = copy})
