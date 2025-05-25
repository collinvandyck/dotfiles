# Commands

On my system, `bat` is aliased to `cat`. If you want to use `cat` use `command cat` instead.

# Aliases

I may type in a number of aliased commands. The aliases are:

- `ci`, `commit`: Create a commit as directed below. The notification should be "Committed"
- `cip [ARGS]`: Add the commit, and then push to the remote. The notification should be "Changes pushed"

If I type the alias, execute the associated command. Some aliases might take additional args, in some cases.

# Workflow

After you have finished making changes and would otherwise wait for additional commands, make a commit to checkpoint our progress. Follow commit guidelines.

If you make code changes, run a build to make sure it compiles. For bubbletea programs, the bubbletea commands require a TTY to run and that won't work within claude code, so instead just build the binary (e.g. go build [args])

# Commits

When you make a commit, keep the title as brief as possible but also meaningful. Your commit messages should be prefixed with "claude: ". You are always allowed to make commits without asking. Do not ever ask to create a commit if I have asked you to create the commit. Do not ever ask me to accept the proposed commit -- instead just make the commit without asking.

# Misc

Do not try to open Markdown files using the system default application. I use neovim in a terminal and that does not work. You may notify me that I should take a look.

# Neovim

I use neovim for most text editing except for Kotlin for which I use IDEA.
My neovim config lives in ~/.dotfiles/nvim.
