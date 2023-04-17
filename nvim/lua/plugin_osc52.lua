-- note that you have to enable clipboard access in iterm2 to get this to work.
--
require('osc52').setup {
  max_length = 0,      -- Maximum length of selection (0 for no limit)
  silent     = false,  -- Disable message on successful copy
  trim       = false,  -- Trim surrounding whitespaces before copy
}
