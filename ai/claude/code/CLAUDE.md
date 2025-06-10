# General Guidance

- NEVER praise me, or my questions, or my code.
- NEVER end a sentence with !
- If I challenge you on a response for correctness, DO NOT assume I am automatically right. Search if you need to. I'm looking for objective truths and not to be right myself.
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

# Neovim

I use neovim for most text editing except for Kotlin for which I use IDEA.

- My neovim config lives in ~/.dotfiles/nvim.
- The neovim init is in nvim/init.lua.
- The nvim/lua/plugins/nvim-lspconfig.lua

# Git

- Repos by default use `main` as the default branch unless otherwise configured.
- if you want to view the changes on the current branch for a changeset use the diff against the merge base, e.g.: `git diff $(git merge-base @ origin/{main,master})`

# Reviewer First Pull Requests (RFPRs)

When I ask you to create an RFPR or commits in RFPR style, follow these principles:

## Core Concept
PRs should tell a coherent story, guiding reviewers through changes systematically. Structure your work to respect reviewers' time and provide clear, logical change narratives.

## PR Structure
- **Title**: Be specific and descriptive about what the PR accomplishes (avoid generic titles like "fix bug")
- **Description**: Provide comprehensive context including:
  - Links to relevant tickets/issues
  - Overview of the problem and business goal
  - Description of your approach
  - Any complex areas that need extra attention
  - Edge cases and potential risks

## Commit Guidelines
- Keep commits focused with limited scope
- Separate high-value changes (business logic) from low-value changes (formatting, refactoring)
- Write descriptive commit titles
- Use full sentences in commit messages explaining the purpose
- Build commits that tell a clear, logical story of the changes
- Avoid rewriting commits after initial review feedback
- It's better to have a commit contain very related changes across files than to have separate commits for all of the files.

## Workflow
- Use `git reset` to reorganize commits when needed
- Structure commits to guide reviewers through the changes progressively

## Co-Author

- **VERY IMPORTANT**: Do not include written by or co-authored by in commit messages.
- **VERY IMPORTANT**: Do not include "🤖 Generated with Claude Code" or "Co-Authored-By: Claude <noreply@anthropic.com>" in commit messages.
