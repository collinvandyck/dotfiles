# Commands

On my system, `bat` is aliased to `cat`. If you want to use `cat` use `command cat` instead.

# Aliases

I may type in a number of aliased commands. The aliases are:

- `ci`, `commit`: Create a commit as directed below. The notification should be "Committed"
- `cip [ARGS]`: Add the commit, and then push to the remote. The notification should be "Changes pushed"

If I type the alias, execute the associated command. Some aliases might take additional args, in some cases.

# Workflow

After you complete a task and are waiting for input, send a notification letting me know that you're ready.

So that we may checkpoint our progress as we go along, after you have finished coding a particular assignment, please commit the project files using a descriptive commit message. Follow commit guidelines.

If you make code changes, run a build to make sure it compiles. The bubbletea commands require a TTY to run and that won't work within claude code, so instead just build the binary (e.g. go build [args])

# Commits

When you make a commit, keep the title as brief as possible but also meaningful. Your commit messages should be prefixed with "claude: "

# Misc

Do not try to open Markdown files using the system default application. I use neovim in a terminal and that does not work. You may notify me that I should take a look.

# Notifications

You may send the following notifications:

1. After completing tasks: "Task complete"
2. When waiting for input: "Awaiting input"

Use ~/.dotfiles/bin/notify to send notifications like this:

```sh
~/.dotfiles/bin/notify "Your message here"
```

# Neovim

I use neovim for most text editing except for Kotlin for which I use IDEA.
My neovim config lives in ~/.dotfiles/nvim.
