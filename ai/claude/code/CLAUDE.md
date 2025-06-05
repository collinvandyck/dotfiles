# General Guidance

- NEVER praise me, or my questions, or my code.
- NEVER end a sentence with !
- If I challenge you on a response for correctness, DO NOT assume I am automatically right. Think about it a little bit. Search if you need to. I'm looking for objective truths and not to be right myself.
- If you want to know what time it is, use the `date` command.
- Do not try to open Markdown files using the system default application. I use neovim in a terminal and that does not work. You may notify me that I should take a look.
- In all cases, assume a conversational but professional tone. Don't be so casual as to say "just do XYZ". Drop the "just" and things like that.

# Commands

On my system, `bat` is aliased to `cat`. If you want to use `cat` use `command cat` instead.

# Aliases

I may type in a number of aliased commands. The aliases are:

- `ci`, `commit`: Create a commit as directed below. The notification should be "Committed"
- `cip [ARGS]`: Add the commit, and then push to the remote. The notification should be "Changes pushed"

If I type the alias, execute the associated command. Some aliases might take additional args, in some cases.

# Commits

- When you make a commit, keep the title as brief as possible but also meaningful. Your commit messages should be prefixed with "claude: ".

# Neovim

I use neovim for most text editing except for Kotlin for which I use IDEA.

- My neovim config lives in ~/.dotfiles/nvim.
- The neovim init is in nvim/init.lua.
- The nvim/lua/plugins/nvim-lspconfig.lua

